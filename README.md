# vector-1mb-logs-to-datadog-logs

## What is this?

A sandbox/lab repo for seeing how Vector can reduce take a log with a size above 1MB, transform the data and reduce it's size and then send it to the Datadog logs API.

## Why?

A customer had a usecase where they wanted to send logs that contained a large complex XML dump that contained over 1MB of information.

Datadog logs have a 1MB limit, anything past that limit is truncated (See https://docs.datadoghq.com/logs/guide/log-collection-troubleshooting-guide/?tab=linux#truncated-logs)

Vector and it's enterprise implementation, Observability Pipelines, can be used to slice-and-dice the log into something Datadog would accept. 

## How?

In this demo, Vector is running a simple topology in which the `chunky_http_json` source fetches a JSON entry from the a local API instance that serves a log greater than 1MB (the body is an escaped XML string that's 1MB, taken from: https://examplefile.com/code/xml/1-mb-xml)

It then uses the `parse_xml` function to read the XML, and convert it to JSON, and it then sends those logs off to stdout via the `console` sink for debugging.

> WIP: Figure out a way of slicing the now JSON-ified log into smaller parts with VRL

To run this scenario, make sure you have the `DD_API_KEY` environment variable set to your Datadog
API key, for example with `envchain`:

```
$ envchain --set vector_datadog DD_API_KEY
ector_datadog.DD_API_KEY: 123
$ envchain env vector_datadog docker compose up
```

Run the composer:

```bash
$ docker compose up
```

You should then see the Vector container running, fetching a log from the DummyJSON API and then sending it to Datadog

```
$ docker compose up
[+] Running 1/0
 ✔ Container vector-1mb-logs-to-datadog-logs-1  Created                                                                                                                                                                                                                                                                                                         0.0s
WARN[0000] /Users/peter.souter/projects/vector-1mb-logs-to-datadog-logs/docker-compose.yml: `version` is obsolete
kilgrave-1  | 2024/07/09 13:08:19 imposter stubs/error.imp.json loaded
kilgrave-1  | 2024/07/09 13:08:19 The fake server is on tap now: kilgrave:80
vector-1    | 2024-07-09T13:13:29.087916Z  INFO vector::app: Log level is enabled. level="info"
vector-1    | 2024-07-09T13:13:29.091076Z  INFO vector::app: Loading configs. paths=["/etc/vector/vector.toml"]
vector-1    | 2024-07-09T13:13:29.100439Z  INFO vector::topology::running: Running healthchecks.
vector-1    | 2024-07-09T13:13:29.100624Z  INFO vector::topology::builder: Healthcheck passed.
vector-1    | 2024-07-09T13:13:29.100721Z  INFO vector: Vector has started. debug="false" version="0.30.0" arch="aarch64" revision="38c3f0b 2023-05-22 17:38:48.655488673"
vector-1    | 2024-07-09T13:13:29.102300Z  INFO vector::internal_events::api: API server running. address=0.0.0.0:8686 playground=http://0.0.0.0:8686/playground
vector-1    | {"body":"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<library>\n<book>\n\t<title>Velit eius rerum aliquam est.</title>\n\t<author>Norma Haley</author>\n\t<genre>totam</genre>\n\t<year>1970</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Laboriosam minus reprehenderit.</title>\n\t<author>Jocelyn Kris</author>\n\t<genre>commodi</genre>\n\t<year>1988</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Sint sequi totam sunt.</title>\n\t<author>Audie Pagac PhD</author>\n\t<genre>dignissimos</genre>\n\t<year>1975</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Ipsum molestiae enim omnis.</title>\n\t<author>Judy Moen</author>\n\t<genre>eos</genre>\n\t<year>1972</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Ut pariatur dolorum aspernatur.</title>\n\t<author>Leonor Strosin</author>\n\t<genre>totam</genre>\n\t<year>1972</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Culpa repellendus impedit quis.</title>\n\t<author>Ms. Caroline Reichert MD</author>\n\t<genre>molestias</genre>\n\t<year>2000</year>\n\t<publisher>https://examplefile.com</publisher>\n</book>\n<book>\n\t<title>Dolores vero id rerum.</title>\n\t<author>Tobin Thompson
[Truncated as it's a big string]
```

You can now see the log within the Datadog Logs explorer:
![image](https://github.com/user-attachments/assets/a399b0ca-565a-4dbb-86c8-c2ffe0b0dfb1)

You can also use the Datadogs Log Search API to find the log and see it's JSON-ified XML result with tools like `jq`:

```bash
response=$(curl -L -X POST "https://api.datadoghq.eu/api/v2/logs/events/search" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" --data-raw '{
  "filter": {
    "from": "now-2d",
    "to": "now",
    "query": "source:vector"
  },
  "page": {
    "limit": 1000
  }
}')

echo $response | jq
```

An example, again using the `envchain` tool (Note: You will also need an App Key for this):

```bash
$ envchain vector_datadog ENV bash curl_logs.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  834k  100  834k  100   124   994k    147 --:--:-- --:--:-- --:--:--  993k
[
  {
    "id": "AgAAAZK-LaMOxSqNiQAAAAAAAAAYAAAAAEFaSy1MYXhkQUFDVlVYM2NDSnRPekFBQQAAACQAAAAAMDE5MmJlMzctNGQ3MC00MGE5LTgwMGUtNmVmNjgzMmZlODJl",
    "type": "log",
    "attributes": {
      "attributes": {
        "library": {
          "book": [
            {
              "year": "1970",
              "author": "Norma Haley",
              "genre": "totam",
              "publisher": "https://examplefile.com",
              "title": "Velit eius rerum aliquam est."
            },
            {
              "year": "1988",
              "author": "Jocelyn Kris",
              "genre": "commodi",
              "publisher": "https://examplefile.com",
              "title": "Laboriosam minus reprehenderit."
            },
            {
              "year": "1975",
              "author": "Audie Pagac PhD",
              "genre": "dignissimos",
              "publisher": "https://examplefile.com",
              "title": "Sint sequi totam sunt."
            },
[TRUNCATED LOG RESULT]
{
              "year": "2022",
              "author": "Ms. Leanna Nitzsche",
              "genre": "corrupti",
              "publisher": "https://examplefile.com",
              "title": "Aliquam vero."
            },
            {
              "year": "1984",
              "author": "Dr. Alvah Leuschke PhD",
              "genre": "quia",
              "publisher": "https://examplefile.com",
              "title": "Placeat non."
            }
          ]
        },
        "source_type": "http_client",
        "timestamp": 1729767514894
      },
      "status": "info",
      "timestamp": "2024-10-24T10:58:34.894Z",
      "tags": [
        "datadog.submission_auth:api_key",
        "source:vector"
      ]
    }
  }
]
```