#!/bin/bash

##########################################################################################
# The plugin depends on infrastructure that cannot easily run on desktop operating systems
# We therefore run some basic infrastructure tests against a deployed reverse proxy
##########################################################################################

API_URL='http://localhost:3000'
ACCESS_TOKEN='42665300-efe8-419d-be52-07b53e208f46'
RESPONSE_FILE=response.txt

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# First authenticate as a client to get an opaque token
#
echo '1. Acting as a client to get an access token ...'
HTTP_STATUS=$(curl -s -X POST http://localhost:8443/oauth/v2/oauth-token \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "client_id=test-client" \
-d "client_secret=secret1" \
-d "grant_type=client_credentials" \
-o $RESPONSE_FILE -w '%{http_code}')    
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered authenticating as a client, status: $HTTP_STATUS"
  exit 1
fi
OPAQUE_ACCESS_TOKEN=$(cat "$RESPONSE_FILE" | jq -r .access_token)
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Unable to get an opaque access token"
  exit 1
fi
echo '1. Successfully authenticated the client and retrieved an access token'

#
# Verify that a client request without an access token fails with a 401
#
echo '2. Testing GET request without an access token ...'
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo "*** GET request without valid access token failed, status: $HTTP_STATUS"
  exit
fi
echo '2. GET request received 401 when no valid access token sent'

#
# Verify that a client request without an access token fails with a 401
#
echo '3. Testing GET request with a valid access token ...'
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-H "Authorization: Bearer $OPAQUE_ACCESS_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** GET request with a valid access token failed, status: $HTTP_STATUS"
  exit
fi
echo '3. GET request received a valid API response when an opaque access token was sent'

