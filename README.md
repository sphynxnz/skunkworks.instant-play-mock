# Instant Play Mock Service

## Overview
This is the mock for **_instant play service_** used by IGT to do performance testing of the IGT Connect interface to the Lotto NZ EBO API service endpoints which include the following:

|Resource | Description | API |
| --- | --- | --- |
| Token | Generate single use token | POST /api/auth/v1/tokenreferences |
| Token | Verify single use token |GET /api/auth/v1/tokenreferences/{_uuid-token_} |
| Wallet | Get wallet balance | GET api/instantplay/v1/users/{_userid_}/wallets?include=user |
| Wallet | Debit wallet | POST /api/instantplay/v1/users/{_userid_}/wallets/debits |
| Wallet | Credit wallet | POST /api/instantplay/v1/users/{_userid_}/wallets/debits/{_debittransid_} |
| Wallet | Refund debit | DELETE /api/instantplay/v1/users/{_userid_}/wallets/debits/{_debittransid_} |
| Wallet | Rollback debit | POST /api/instantplay/v1/users/{_userid_}/wallets/debits |

The mock service implementation is taken in the context where the client (IGT Connect) will directly invoke the APIs exposed. This means that only the required header parameters visible to the client have to be provided as per API specifications. Also note that there is no triggering of an actual or simulated **_sideband_** call since the F5/LTM is not involved in the interactions, so the other header parameters such as _USER_ID_, _ESI_SID_ and _USER_NAME_ are not required.

## Mock Implementation
The mock service was implementd using the node-based version of **_mountebank_**. See http://www.mbtest.org/ for more details on how it works.

The table below shows the complete list of software components used to implement the mock service.

|Software | Description | 
| --- | --- |
| **_mountebank_** | **npm** package primarily used to build the mock service |
| **_faker_** | **npm** package for generating fake user names and locations |
| **_uuid_** | **npm** package used for generating UUID V4 tokens |
| **_randomstring_** | **npm** package used for generating random ESI user id |
| **_moment-timezone_** | **npm** package used for generating ISO 8601 date time with time zone |

## Mock Features
The mock service implementation supports smart simulation of the mock responses. The current implementation provides just enough features to support the performance testing of the IGT Connect component. The intent is to expand the features to include full coverage of both sunny and rainy date scenarios for unit testing purposes. 

The baseline implementation currently supports the following features:
- Creates dummy user data if none exists yet to provide _userid_, _first name_ and _location_ information
- Returns consistent user data in a get balance API call
- Enforces one-time use of single use token (ssoToken)
- Returns a consistent _session id_ when single use token is verified
- Enforces matching of _debit transaction id_ in a credit or refund API call with the _debit transaction id_ generated of a previous debit API call
- Enforces matching of _reference id_ in a rollback API call with the _reference id_ of a previous debit API call
- Supports idempotent API calls for debit, credit, refund and rollback
- Enforces consistency between the various API calls. For instance, a debit transaction that has as associated credit transation cannot be refunded or rollbacked and vice versa

## Installation and Startup


### 1. Download or clone repository

```bash
git clone https://github.com/sphynxnz/skunkworks.instant-play-mock.git
```

### 2. Install required npm packages

Change directory to the repository and install the required npm packages globally. Note that **_mountebank_** requires any npm package used by the mock implementation for _injection_ purposes to be installed globally.

```bash
npm install mountebank -g
npm install uuid -g
npm install faker -g
npm install moment-timezone -g
npm install randomstring -g
```

### 3. Start the mock service

```bash
npm run start:instant-play:mock
```

A successful startup will display something like this:
```bash
> instant-play-mock@0.0.1 start:instant-play:mock /Users/fcontreras/NODEAPPS/instant-play-mock
> mb --configfile instant-play-imposter.ejs --allowInjection

info: [mb:2525] mountebank v1.12.0 now taking orders - point your browser to http://localhost:2525 for help
warn: [mb:2525] Running with --allowInjection set. See http://localhost:2525/docs/security for security info
info: [mb:2525] PUT /imposters
info: [http:8090 instant-play-mock] Open for business...
```

## Dockerised Mock Service

A docker image can be created of the mock service. 

1. Install docker if not installed yet   
2. Change to the repository directory
3. Build docker image
```bash
docker built -t instant-play-mock .
```
4. Start docker instance of the mock service
```bash
docker run -it -p 2525:2525 -p 8090:8090 instant-play-mock
```
Port 2525 is mountebank's own internal port number and 8090 is the internal port number of the instant play mock service. The internal ports can be mapped to external ports most appropriate for the installation as shown in the example below.
```bash
docker run -it -p 5555:2525 -p 8888:8090 instant-play-mock
```

## Sample Requests and Responses
### 1. Generate single token from JWT

**Request**
```bash
curl -X POST \
  http://localhost:8090/api/auth/v1/tokenreferences \
  -H 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL215bG90dG8uY28ubnovIiwianRpIjoiYjg2NjQxYjItN2I5Ni00ZDFjLTg2NTAtY2I4OGI1OTBkNDZlIiwiaWF0IjoxNTAxODE4NjM2LCJzdWIiOiJRQVRlc3QyMTM5MTFAdGVzdC5jb20iLCJleHAiOjE1MDI0MjM0MzYsInVzZXJfaWQiOiIxMDgzNjAwMDAiLCJkZXZpY2VJbmZvIjp7Im9zIjoiaU9TIiwidHRsQ29udGV4dCI6IkNsYXNzMSJ9fQ.fOKgkILIjIDlvNalnj2eaPsQo8UsBAahPpjTzFcHvAw'
```
**Response**
```json
{
    "data": {
        "tokenreferences": [
            {
                "id": "2d41fbd6-5e49-4043-ab96-420681ac49ed"
            }
        ]
    }
}
```

### 2. Generate single use token from UUID V4

**Request**
```bash
curl -X POST \
  http://localhost:8090/api/auth/v1/tokenreferences \
  -H 'authorization: Bearer b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b'
```
**Response**
```json
{
    "data": {
        "tokenreferences": [
            {
                "id": "7e39eb84-cf7e-4de3-a183-6e42a96d01bd"
            }
        ]
    }
}
```

### 3. Verify single use token

**Request**
```bash
curl -X GET \
  'http://localhost:8090/api/auth/v1/tokenreferences/7e39eb84-cf7e-4de3-a183-6e42a96d01bd?include=user.id'
```
**Response**
```json
{
    "data": {
        "tokenreferences": [
            {
                "id": "b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b",
                "user": {
                    "id": "571339160"
                }
            }
        ]
    }
}
```

### 4. Debit wallet

**Request**
```bash
curl -X POST \
  http://localhost:8090/api/instantplay/v1/users/123456789/wallets/debits \
  -H 'authorization: Bearer b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b' \
  -H 'content-type: application/json' \
  -H 'x-device-id: 1' \
  -H 'x-request-id: DPR00000001' \
  -d '{
	"data": {
		"debits": [{
			"amount": 50.11,
			"game": {
				"id": "200-1173-001",
				"provider": {
					"id": "EI1"
				}
			}
		}]
	}
}'
```
**Response**
```json
{
    "data": {
        "debits": [
            {
                "id": 1000000000,
                "amount": 50.11,
                "date": "2017-08-10T12:20:31+12:00",
                "wallet": {
                    "balance": 169.71
                }
            }
        ]
    }
}
```

### 5. Credit wallet

**Request**
```bash
curl -X POST \
  http://localhost:8090/api/instantplay/v1/users/123456789/wallets/debits/1000000000/credits \
  -H 'authorization: Bearer b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b' \
  -H 'content-type: application/json' \
  -H 'x-device-id: 1' \
  -H 'x-request-id: DPR10000001' \
  -d '{
	"data": {
		"credits": [{
			"amount": 80.88,
			"game": {
				"id": "200-1173-001",
				"provider": {
					"id": "EI1"
				}
			}
		}]
	}
}'
```
**Response**
```json
{
    "data": {
        "credits": [
            {
                "id": 1000000001,
                "amount": 80.88,
                "date": "2017-08-10T12:22:14+12:00",
                "wallet": {
                    "balance": 250.59
                }
            }
        ]
    }
}
```

### 6. Refund debit

**Request**
```bash
curl -X DELETE \
  http://localhost:8090/api/instantplay/v1/users/123456789/wallets/debits/1000000000 \
  -H 'authorization: Bearer b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b' \
  -H 'content-type: application/json' \
  -H 'x-device-id: 1' \
  -H 'x-request-id: DPR20000001'
```
**Response**
```json
{
    "data": {
        "refunds": [
            {
                "id": 1000000001,
                "amount": 50.11,
                "date": "2017-08-10T12:24:23+12:00",
                "wallet": {
                    "balance": 542.46
                }
            }
        ]
    }
}
```
### 7. Rollback debit

**Request**
```bash
curl -X DELETE \
  'http://localhost:8090/api/instantplay/v1/users/123456789/wallets/debits?reference=DPR00000001' \
  -H 'authorization: Bearer b4fa11b0-b3e3-4e0c-b2d7-f667ae4b660b' \
  -H 'content-type: application/json' \
  -H 'x-device-id: 1' \
  -H 'x-request-id: DPR30000001'
```
**Response**
```json
{
    "data": {
        "refunds": [
            {
                "id": 1000000001,
                "amount": 50.11,
                "date": "2017-08-10T12:25:47+12:00",
                "wallet": {
                    "balance": 748.77
                }
            }
        ]
    }
}
```
