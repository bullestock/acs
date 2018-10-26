# Permissions API

## Query permission

```
api/v1/permissions POST
{
  api_token: "83b2d966f444a122c1078ae23e04e82dcd12a9313b953239a0a633df866892b2",
  "card_id": "0123456789"
}
```
Returns
```
{
  allowed: true,
  id: 87,
  name: "Bo Bolinski"
}
```

# Log API

## Add log entry

```
api/v1/logs POST
{
  api_token: "83b2d966f444a122c1078ae23e04e82dcd12a9313b953239a0a633df866892b2",
  log:
  {
    message: "Granted entry",
    user_id: 87
  }
}
```

## Get log entries

```
api/v1/logs?api_token=83b2d966f444a122c1078ae23e04e82dcd12a9313b953239a0a633df866892b2 GET
```

Returns all log entries for this machine

```
api/v1/logs?api_token=83b2d966f444a122c1078ae23e04e82dcd12a9313b953239a0a633df866892b2&user_id=78 GET
```

Returns all log entries from specified user for this machine

```
api/v1/logs?api_token=83b2d966f444a122c1078ae23e04e82dcd12a9313b953239a0a633df866892b2&last=3 GET
```

Returns last 3 log entries user for this machine
