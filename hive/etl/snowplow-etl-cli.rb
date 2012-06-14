# Copyright (c) 2012 SnowPlow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author::    Alex Dean (mailto:alex@snowplowanalytics.com)
# Copyright:: Copyright (c) 2012 SnowPlow Analytics Ltd
# License::   Apache License Version 2.0

require 'config'
require 's3_utils'
require 'emr_client'

# This Ruby script runs the daily ETL (extract, transform, load)
# process which transforms the raw CloudFront log data into
# SnowPlow-formatted Hive data tables, optimised for analysis.
#
# This is a three-step process:
# 1. Extract the CloudFront log files to a temporary SnowPlow event data table (using the custom Deserializer)
# 2. Load the temporary event data into the final SnowPlow data table, partitioning by date and user
# 3. Archive the CloudFront log files by moving them into a separate bucket
#
# Note that each step is only actioned if the previous step succeeded without error.
#
# Please make sure that both of these are installed before running this script.
config = Config.get_config()

exit_code = 0
begin
  S3Utils.upload_query(config)
  EmrClient.run_etl(config)
  S3Utils.archive_logs(config)

rescue SystemExit => e
  exit_code = -1

rescue Exception => e
  STDERR.puts("Error: " + e.message)
  STDERR.puts(e.backtrace.join("\n"))
  exit_code = -1
end

exit(exit_code)