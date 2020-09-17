# SierraCheckInCardPoller

[![Build Status](https://travis-ci.com/NYPL/SierraCheckInCardPoller.svg?branch=main)](https://travis-ci.com/NYPL/SierraCheckInCardPoller) [![GitHub version](https://badge.fury.io/gh/nypl%2FsierraCheckInCardPoller.svg)](https://badge.fury.io/gh/nypl%2FsierraCheckInCardPoller)

This function fetches updates to the check-in cards & boxes from the Sierra PostgreSQL database, which is used to add these records to serials in Shared Collection Catalog. This data is not exposed through the Sierra API, and to avoid taxing the database this fetches updates periodically and stores them in a SQLite database, which in turn is stored in a s3 bucket. This makes it available to other functions or apps on an as-needed basis, without having to run a full RDS database instance.

## Data Structure

The data retrieved by this function represents the "check-in" cards, which provide information on the most recent acquisitions of a specific periodical by the library. Each card can contain up to 120 "boxes", each of which represents a single issue of the periodical that has been or should be received by the library. Each card is associated with a single holding record, which describes the library's overall holdings of the serial (or a part of them in instances where there are multiple holdings).

Each box contains a basic set of information regarding that issue. This function executes a query that retrieves a single row per box and stores them in table with the following fields. These fields are retrieved and transformed as necessary by the functions that need to access them.

### Fields

- id: Identifier for the check-in box
- holding_record_id: Internal identifier for the related holding record
- record_num: The external identifier for the related holdings record, can be used to retrieve records
- holding_record_cardlink_id: Identifier for the box's parent check-in card
- box_count: This box's position on the check-in card. Can be up to 120.
- enum_level_a: Character describing the box's issue, e.g. "iss. 23". This is the first step in the hierarchy with all of the `enum_level_CHAR` fields
- enum_level_b: Second level in the enumeration hierarchy
- enum_level_c: Third level in the enumeration hierarchy
- enum_level_d: Fourth level in the enumeration hierarchy
- enum_level_e: Fifth level in the enumeration hierarchy
- enum_level_f: Sixth level in the enumeration hierarchy
- enum_level_g: Seventh level in the enumeration hierarchy
- enum_level_h: Eighth level in the enumeration hierarchy
- chron_level_i: Date value for the coverage of box entry. This is the top level in the date hierarchy and usually corresponds to year
- chron_level_j: Second value in the date coverage hierarchy, usually corresponds to month
- chron_level_k: Third value in the date coverage hierarchy, usually corresponds to day
- chron_level_l: Fourth value in the date coverage hierarchy, usually not used
- chron_level_m: Fifth value in the date coverage hierarchy, usually not used
- chron_level_i_trans_date: Date value for the date the box was received. This top level in the hierarchy usually corresponds to year
- chron_level_j_trans_date: Second value in the date received hierarchy, usually corresponds to month
- chron_level_k_trans_date: Third value in the date received hierarchy, usually corresponds to day
- chron_level_l_trans_date: Second value in the date received hierarchy, not usually used
- chron_level_m_trans_date: Second value in the date received hierarchy, not usually used
- note: A general note field describing the contents of the box entry
- box_status_code: A single character code describing the status of the box contents. Most frequently `A` for "Available" but other codes correspond to "Missing" or "In Transit"
- claim_cnt: An unclear counter for the number of "claims"
- copies_cnt: A integer providing the number of copies of the serial received for this box
- url: A URL to a digital version of the box holdings, not usually populated
- is_suppressed: A boolean flag for if this record should be suppressed in the front end
- staff_note: An internal note field not for public display

## Requirements

- ruby 2.7
- AWS CLI

## Dependencies

- nypl_ruby_util@0.0.3
- aws-sdk-s3@1.74.0
- rspec@3.9.0
- mocha@1.11.2
- pg (see below)
- sqlite3 (see below)

## Environment Variables

- DB_HOST: Hostname for the Sierra database instance
- DB_PORT: Port where the database instance is available
- DB_NAME: Name of the Sierra database instance
- DB_USER: User for Sierra database instance (should be encrypted)
- DB_PSWD: Password for Sierra database instance (NEEDS TO BE ENCRYPTED)
- DB_QUERY: Query to execute to retrieve the check-in cards/boxes. This should be constructed with the help of the ILS team
- SQLITE_FILE: Name of the sqlite file to create in `/tmp` and store in s3

## Installation

This function is developed using the AWS SAM framework, [which has installation instructions here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)

To install the dependencies for this function, they must be bundled for this framework and should be done with `rake run_bundler`

### Layers

This function uses a layer to include the `pg` and `sqlite3` dependencies because the AWS Lambda environment does not included the shared C/C++ libraries that they need to function. The layer is built on the `amazonlinux` docker image and from there deployed as a layer. This is also used in the SAM local environment for local runs (see the sam `YAML` files for how it is included).

## Usage

To run the function locally it may be invoked with rake, where FUNCTION is the name of the function you'd like to invoke from the `sam.local.yml` file:

`rake run_local`

## Testing

Testing is provided via `rspec` with `mocha` for stubbing/mocking. The test suite can be invoked with `rake test`
