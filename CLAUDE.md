# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a demonstration repository showing how Vector (and Observability Pipelines) can handle logs exceeding Datadog's 1MB limit by transforming large XML payloads into structured JSON before ingestion.

**Architecture:**
- **Killgrave**: Mock HTTP server serving test logs with 1MB+ XML content
- **Vector**: Log processing pipeline that fetches, transforms, and routes logs
- **Datadog**: Final destination for processed logs

**Data Flow:**
1. Vector's `http_client` source scrapes JSON logs from Killgrave (every 60s)
2. The `remap` transform parses embedded XML strings into JSON structures using `parse_xml!`
3. Logs are sent to both stdout (console sink) and Datadog Logs API

## Common Commands

### Starting the Environment

Requires `DD_API_KEY` environment variable. Example using envchain:

```bash
envchain vector_datadog docker compose up
```

Or set directly:

```bash
DD_API_KEY=your_key docker compose up
```

The `DD_SITE` environment variable can also be set if using a non-US Datadog site (e.g., `datadoghq.eu`).

### Querying Logs from Datadog

Use the provided script to search for processed logs (requires `DD_API_KEY` and `DATADOG_APP_KEY`):

```bash
bash curl_logs.sh | jq
```

Or with envchain:

```bash
envchain vector_datadog bash curl_logs.sh
```

### Vector Configuration

Vector config is in `vector/vector.toml`. After changes, restart the container:

```bash
docker compose restart vector
```

### Killgrave Mock Server

Killgrave configuration is in `killgrave/error/config.yml` with imposters defined in `killgrave/error/stubs/error.imp.json`.

Available endpoints:
- `/error/bigerror` - Returns 1MB+ XML payload (default endpoint used by Vector)
- `/error/smallerror` - Returns smaller XML payload for testing

## Key Components

### Vector Pipeline (vector/vector.toml)

- **Source** (`dummy_http_json`): HTTP client polling Killgrave every 60 seconds
- **Transform** (`xml_to_json`): VRL (Vector Remap Language) script that:
  - Sets `.ddsource = "vector"` for Datadog source tagging
  - Adds timestamp with `now()`
  - Parses XML from `.message` field using `parse_xml!` function
- **Sinks**:
  - `stdout`: JSON console output for debugging
  - `datadog_logs`: Ships to Datadog Logs API

### VRL Transform Logic

The key transformation uses Vector's `parse_xml!` function with specific options:
- `text_key: "value"` - Names the key for XML text nodes
- `parse_number: false` - Keeps numeric values as strings to prevent type issues

## Development Notes

- Vector API and playground available at `localhost:8686`
- Killgrave mock server runs on `localhost:8090`
- The sample XML file is sourced from https://examplefile.com/code/xml/1-mb-xml
- Datadog API endpoint in `curl_logs.sh` uses EU region (`api.datadoghq.eu`) - adjust for other regions
