define({ "api": [
  {
    "type": "get",
    "url": "/update",
    "title": "Receive upload events",
    "description": "<p>Events are passed in the <a href=\"https://developer.mozilla.org/en-US/docs/Web/API/EventSource\">EventStream</a> format.</p>",
    "name": "GetUpdates",
    "group": "Update",
    "version": "0.0.0",
    "filename": "./live-share/resource/update.lua",
    "groupTitle": "Update"
  },
  {
    "type": "get",
    "url": "/upload/:id",
    "title": "Retrieve a file",
    "name": "GetUpload",
    "group": "Upload",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": ""
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "./live-share/resource/upload.lua",
    "groupTitle": "Upload"
  },
  {
    "type": "get",
    "url": "/upload/:id/thumbnail",
    "title": "Retrieve a thumbnail",
    "name": "GetUploadThumbnail",
    "group": "Upload",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": ""
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "./live-share/resource/upload.lua",
    "groupTitle": "Upload"
  },
  {
    "type": "get",
    "url": "/upload/query",
    "title": "Search for uploads",
    "name": "QueryUpload",
    "group": "Upload",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "DateTime",
            "optional": true,
            "field": "before",
            "description": "<p>Select uploads created before given timestamp. (query parameter)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "order_asc",
            "description": "<p>... (query parameter)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "order_desc",
            "description": "<p>... (query parameter)</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "limit",
            "defaultValue": "100",
            "description": "<p>... (query parameter)</p>"
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": ""
          },
          {
            "group": "Success 200",
            "type": "DateTime",
            "optional": false,
            "field": "time",
            "description": "<p>ISO date time format</p>"
          },
          {
            "group": "Success 200",
            "type": "String",
            "optional": false,
            "field": "user_name",
            "description": ""
          },
          {
            "group": "Success 200",
            "type": "String",
            "optional": false,
            "field": "category_name",
            "description": ""
          },
          {
            "group": "Success 200",
            "type": "String",
            "allowedValues": [
              "\"image\"",
              "\"video\""
            ],
            "optional": false,
            "field": "media_type",
            "description": ""
          }
        ]
      },
      "examples": [
        {
          "title": "HTTP/1.1 200 OK",
          "content": "HTTP/1.1 200 OK\n[\n    {\n        \"id\": 42,\n        \"time\": \"2007-04-05T12:30-02:00Z\",\n        \"user_name\": \"Mario\",\n        \"category_name\": \"Portal\",\n        \"media_type\": \"image\"\n    },\n    {\n        \"id\": 45,\n        \"time\": \"2007-05-12T7:33-06:03Z\",\n        \"user_name\": \"Luigi\",\n        \"category_name\": \"Witcher\",\n        \"media_type\": \"video\"\n    }\n]",
          "type": "json"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "./live-share/resource/upload.lua",
    "groupTitle": "Upload"
  },
  {
    "type": "post",
    "url": "/upload",
    "title": "Upload a file",
    "name": "UploadFile",
    "group": "Upload",
    "permission": [
      {
        "name": "user"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "category",
            "description": "<p>Name of the category. (query parameter)</p>"
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "./live-share/resource/upload.lua",
    "groupTitle": "Upload"
  },
  {
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "optional": false,
            "field": "varname1",
            "description": "<p>No type.</p>"
          },
          {
            "group": "Success 200",
            "type": "String",
            "optional": false,
            "field": "varname2",
            "description": "<p>With type.</p>"
          }
        ]
      }
    },
    "type": "",
    "url": "",
    "version": "0.0.0",
    "filename": "./doc/main.js",
    "group": "_home_henry_Projects_live_share_server_doc_main_js",
    "groupTitle": "_home_henry_Projects_live_share_server_doc_main_js",
    "name": ""
  },
  {
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "optional": false,
            "field": "varname1",
            "description": "<p>No type.</p>"
          },
          {
            "group": "Success 200",
            "type": "String",
            "optional": false,
            "field": "varname2",
            "description": "<p>With type.</p>"
          }
        ]
      }
    },
    "type": "",
    "url": "",
    "version": "0.0.0",
    "filename": "./server/doc/main.js",
    "group": "_home_henry_Projects_live_share_server_server_doc_main_js",
    "groupTitle": "_home_henry_Projects_live_share_server_server_doc_main_js",
    "name": ""
  }
] });
