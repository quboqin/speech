#!/bin/sh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


source $(dirname $0)/PROJECT.sh

curl -X POST -H "Authorization: Bearer "$(gcloud auth print-access-token) \
             -H "Content-Type: application/json; charset=utf-8" --data "{
  'displayName': 'StartStopwatch',
  'priority': 500000,
  'mlEnabled': true,
  'webhookState': 'WEBHOOK_STATE_DISABLED',
  'trainingPhrases': [
    {
      'type': 'TYPE_EXAMPLE',
      'parts': [
        {
          'text': 'start stopwatch'
        }
      ]
    }
  ],

  'result': {
    'action': 'start',
    'messages': [
        {
          'text': {
            'text': [
             'Stopwatch started'
            ]
          }
        }
      ],
    }
,
}" "$SERVICE/intents"
  
curl -X POST -H "Authorization: Bearer "$(gcloud auth print-access-token) \
             -H "Content-Type: application/json; charset=utf-8" --data "{
  'displayName': 'StopStopwatch',
  'priority': 500000,
  'mlEnabled': true,
  'webhookState': 'WEBHOOK_STATE_DISABLED',
  'trainingPhrases': [
    {
      'type': 'TYPE_EXAMPLE',
      'parts': [
        {
          'text': 'stop stopwatch'
        }
      ]
    }
  ],

  'result': {
    'action': 'stop',
    'messages': [
        {
          'text': {
            'text': [
             'Stopwatch stopped'
            ]
          }
        }
      ],
    }
,
}" "$SERVICE/intents"
  
