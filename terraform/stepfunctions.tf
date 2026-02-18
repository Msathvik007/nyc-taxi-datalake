locals {
  nyc_taxi_state_machine_definition = jsonencode({
    Comment = "NYC Taxi pipeline workflow"
    StartAt = "RunGlueJobA"
    States = {
      RunGlueJobA = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.job_a.name
          Arguments = {
            "--BUCKET.$" = "$.BUCKET"
            "--run_id.$" = "$.run_id"
          }
        }
        ResultPath = "$.jobA"
        Retry = [
          {
            ErrorEquals     = ["Glue.AWSGlueException", "States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "QualityGate"
      }

      QualityGate = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.quality_gate.function_name
          Payload = {
            "BUCKET.$"  = "$.BUCKET"
            "run_id.$"  = "$.run_id"
            "threshold" = 0.7
          }
        }
        ResultPath = "$.qualityGate"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "QualityDecision"
      }

      QualityDecision = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.qualityGate.Payload.pass"
            BooleanEquals = true
            Next          = "RunGlueJobB"
          }
        ]
        Default = "Fail"
      }

      RunGlueJobB = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.job_b.name
          Arguments = {
            "--BUCKET.$" = "$.BUCKET"
            "--run_id.$" = "$.run_id"
          }
        }
        ResultPath = "$.jobB"
        Retry = [
          {
            ErrorEquals     = ["Glue.AWSGlueException", "States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "MasterDataFreshnessGate"
      }

      MasterDataFreshnessGate = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.master_data_frehness.function_name
          Payload = {
            "BUCKET.$" = "$.BUCKET"
            "run_id.$" = "$.run_id"
            thresholds = {
              taxi_zone_golden = {
                warn_days = 30
                fail_days = 90
              }
              vendor_golden = {
                warn_days = 90
                fail_days = 180
              }
              ratecode_golden = {
                warn_days = 180
                fail_days = 365
              }
            }
            "sns_topic_arn.$" = "$.sns_topic_arn"
          }
        }
        ResultPath = "$.masterFreshness"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "FreshnessDecision"
      }

      FreshnessDecision = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.masterFreshness.Payload.status"
            StringEquals = "PASS"
            Next         = "RunGlueJobC"
          },
          {
            Variable     = "$.masterFreshness.Payload.status"
            StringEquals = "WARN"
            Next         = "RunGlueJobC"
          }
        ]
        Default = "Fail"
      }

      RunGlueJobC = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.job_c.name
          Arguments = {
            "--BUCKET.$"        = "$.BUCKET"
            "--run_id.$"        = "$.run_id"
            "--sns_topic_arn.$" = "$.sns_topic_arn"
          }
        }
        ResultPath = "$.jobC"
        Retry = [
          {
            ErrorEquals     = ["Glue.AWSGlueException", "States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "RunAllCrawlersInParallel"
      }

      RunAllCrawlersInParallel = {
        Type       = "Parallel"
        ResultPath = "$.crawlers"
        Next       = "RedshiftRunner"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Branches = [
          {
            StartAt = "StartCrawlerYellowTripsEnriched"
            States = {
              StartCrawlerYellowTripsEnriched = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Parameters = { Name = aws_glue_crawler.yellow_trips_enriched.name }
                Next       = "WaitCrawlerYellowTripsEnriched"
              }
              WaitCrawlerYellowTripsEnriched = {
                Type    = "Wait"
                Seconds = 15
                Next    = "GetCrawlerYellowTripsEnriched"
              }
              GetCrawlerYellowTripsEnriched = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:getCrawler"
                Parameters = { Name = aws_glue_crawler.yellow_trips_enriched.name }
                ResultPath = "$.crawler"
                Next       = "CrawlerDoneYellowTripsEnriched"
              }
              CrawlerDoneYellowTripsEnriched = {
                Type = "Choice"
                Choices = [
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "READY"
                    Next         = "CrawlerSuccessYellowTripsEnriched"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "RUNNING"
                    Next         = "WaitCrawlerYellowTripsEnriched"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "STOPPING"
                    Next         = "WaitCrawlerYellowTripsEnriched"
                  }
                ]
                Default = "WaitCrawlerYellowTripsEnriched"
              }
              CrawlerSuccessYellowTripsEnriched = { Type = "Succeed" }
            }
          },
          {
            StartAt = "StartCrawlerTaxiZoneMaster"
            States = {
              StartCrawlerTaxiZoneMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Parameters = { Name = aws_glue_crawler.taxi_zone_master.name }
                Next       = "WaitCrawlerTaxiZoneMaster"
              }
              WaitCrawlerTaxiZoneMaster = {
                Type    = "Wait"
                Seconds = 15
                Next    = "GetCrawlerTaxiZoneMaster"
              }
              GetCrawlerTaxiZoneMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:getCrawler"
                Parameters = { Name = aws_glue_crawler.taxi_zone_master.name }
                ResultPath = "$.crawler"
                Next       = "CrawlerDoneTaxiZoneMaster"
              }
              CrawlerDoneTaxiZoneMaster = {
                Type = "Choice"
                Choices = [
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "READY"
                    Next         = "CrawlerSuccessTaxiZoneMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "RUNNING"
                    Next         = "WaitCrawlerTaxiZoneMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "STOPPING"
                    Next         = "WaitCrawlerTaxiZoneMaster"
                  }
                ]
                Default = "WaitCrawlerTaxiZoneMaster"
              }
              CrawlerSuccessTaxiZoneMaster = { Type = "Succeed" }
            }
          },
          {
            StartAt = "StartCrawlerVendorMaster"
            States = {
              StartCrawlerVendorMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Parameters = { Name = aws_glue_crawler.vendor_master.name }
                Next       = "WaitCrawlerVendorMaster"
              }
              WaitCrawlerVendorMaster = {
                Type    = "Wait"
                Seconds = 15
                Next    = "GetCrawlerVendorMaster"
              }
              GetCrawlerVendorMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:getCrawler"
                Parameters = { Name = aws_glue_crawler.vendor_master.name }
                ResultPath = "$.crawler"
                Next       = "CrawlerDoneVendorMaster"
              }
              CrawlerDoneVendorMaster = {
                Type = "Choice"
                Choices = [
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "READY"
                    Next         = "CrawlerSuccessVendorMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "RUNNING"
                    Next         = "WaitCrawlerVendorMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "STOPPING"
                    Next         = "WaitCrawlerVendorMaster"
                  }
                ]
                Default = "WaitCrawlerVendorMaster"
              }
              CrawlerSuccessVendorMaster = { Type = "Succeed" }
            }
          },
          {
            StartAt = "StartCrawlerRatecodeMaster"
            States = {
              StartCrawlerRatecodeMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Parameters = { Name = aws_glue_crawler.ratecode_master.name }
                Next       = "WaitCrawlerRatecodeMaster"
              }
              WaitCrawlerRatecodeMaster = {
                Type    = "Wait"
                Seconds = 15
                Next    = "GetCrawlerRatecodeMaster"
              }
              GetCrawlerRatecodeMaster = {
                Type       = "Task"
                Resource   = "arn:aws:states:::aws-sdk:glue:getCrawler"
                Parameters = { Name = aws_glue_crawler.ratecode_master.name }
                ResultPath = "$.crawler"
                Next       = "CrawlerDoneRatecodeMaster"
              }
              CrawlerDoneRatecodeMaster = {
                Type = "Choice"
                Choices = [
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "READY"
                    Next         = "CrawlerSuccessRatecodeMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "RUNNING"
                    Next         = "WaitCrawlerRatecodeMaster"
                  },
                  {
                    Variable     = "$.crawler.Crawler.State"
                    StringEquals = "STOPPING"
                    Next         = "WaitCrawlerRatecodeMaster"
                  }
                ]
                Default = "WaitCrawlerRatecodeMaster"
              }
              CrawlerSuccessRatecodeMaster = { Type = "Succeed" }
            }
          }
        ]
      }

      RedshiftRunner = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.redshift_runner.function_name
          Payload = {
            "BUCKET.$"        = "$.BUCKET"
            "run_id.$"        = "$.run_id"
            "sns_topic_arn.$" = "$.sns_topic_arn"
          }
        }
        ResultPath = "$.redshiftRunner"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Fail"
          }
        ]
        Next = "Success"
      }

      Fail = {
        Type = "Fail"
      }
      Success = {
        Type = "Succeed"
      }
    }
    TimeoutSeconds = 10800
  })
}

resource "aws_sfn_state_machine" "pipeline" {
  name       = var.step_function_name
  role_arn   = aws_iam_role.step_functions_execution.arn
  definition = local.nyc_taxi_state_machine_definition
  tags       = var.tags
}
