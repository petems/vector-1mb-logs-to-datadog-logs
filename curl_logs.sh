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