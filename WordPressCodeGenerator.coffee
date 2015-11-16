# in API v0.2.0 and below (Paw 2.2.2 and below), require had no return value
((root) ->
  if root.bundle?.minApiVersion('0.2.0')
    root.Mustache = require("./mustache")
  else
    require("mustache.js")
)(this)

addslashes = (str) ->
    ("#{str}").replace(/[\\']/g, '\\$&')

quotify = (str) ->
    if str.indexOf("'") isnt false and str.indexOf('"') is false
        return "\"#{str}\""
    else
        return "'#{addslashes str}'"


WordPressCodeGenerator = ->

    @url = (request) ->
        return {
            "fullpath" : request.url
        }

    @headers = (request) ->
        headers = request.headers
        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": quotify header_name
                "header_value": quotify header_value
            } for header_name, header_value of headers)
        }

    @body = (request) ->
        json_body = request.jsonBody
        if json_body
            return {
                "has_body": true
                "has_json_body": true
                "json_body_object":@json_body_object json_body, 1
            }

        url_encoded_body = request.urlEncodedBody
        if url_encoded_body
            return {
                "has_body": true
                "has_url_encoded_body": true
                "url_encoded_body": ({
                    "name": quotify name
                    "value": quotify value
                } for name, value of url_encoded_body)
            }

        multipart_body = request.multipartBody
        if multipart_body
            return {
                "has_body": true
                "has_multipart_body": true
                "multipart_body": ({
                    "name": quotify name
                    "value": quotify value
                } for name, value of multipart_body)
            }

        raw_body = request.body
        if raw_body
            return {
                "has_body": true
                "has_raw_body": true
                "raw_body": quotify raw_body
            }

        return {
            "has_bady": false
        }

    @json_body_object = (object, indent = 0) ->
        if object == null
            s = "null"
        else if typeof(object) == 'string'
            s = quotify object
        else if typeof(object) == 'number'
            s = "#{object}"
        else if typeof(object) == 'boolean'
            s = if object then "true" else "false"
        else if typeof(object) == 'object'
            indent_str = Array(indent + 1).join("\t")
            indent_str_children = Array(indent + 2).join("\t")
            indent_str_closing = Array(indent).join("\t")
            closing_comma = if indent - 1 then ',' else ''
            if object.length?
                s = "array(\n" +
                    ("#{indent_str}#{@json_body_object(value, indent+1)}" for value in object).join(',\n') +
                    "\n#{indent_str_closing})#{closing_comma}"
            else
                s = "array(\n" +
                    ("#{indent_str}#{quotify key} => #{@json_body_object(value, indent+1)}" for key, value of object).join(',\n') +
                    "\n#{indent_str_closing})#{closing_comma}"

        return s

    @method = (method) ->
        switch method
            when "GET" then request_function = "wp_remote_get"
            when "POST" then request_function = "wp_remote_post"
            when "HEAD" then request_function = "wp_remote_head"
            else request_function = "wp_remote_request"

        return {
            "function": request_function,
            "name": method,
            "needs_method": request_function is "wp_remote_request"
        }


    @generate = (context) ->
        request = context.getCurrentRequest()
        method = @method request.method.toUpperCase()
        url = @url request
        headers = @headers request
        body = @body request

        view =
            "request": request
            "method": method
            "url": url
            "headers": headers
            "body": body
            "has_args": headers.has_headers or body.has_body or method.needs_method

        template = readFile "php.mustache"
        Mustache.render template, view

    return


WordPressCodeGenerator.identifier =
    "com.alleyinteractive.PawExtensions.WordPressCodeGenerator"
WordPressCodeGenerator.title =
    "WordPress"
WordPressCodeGenerator.fileExtension = "php"
WordPressCodeGenerator.languageHighlighter = "php"

registerCodeGenerator WordPressCodeGenerator
