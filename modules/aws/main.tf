data "aws_region" "current" {}

resource "aws_api_gateway_method" "method" {
  rest_api_id          = "${var.api_id}"
  resource_id          = "${var.api_resource_id}"
  http_method          = "${var.method}"
  authorization        = "${var.authorization}"
  request_validator_id = "${var.request_validator}"

  request_models {
    "application/json" = "${var.request_model}"
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.api_resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"

  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda}/invocations"

  request_templates {
    "application/json" = "${var.request_template}"
  }

  depends_on = ["aws_api_gateway_method.method"]
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.api_resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "200"

  response_parameters {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models {
    "application/json" = "${var.response_model}"
  }

  depends_on = ["aws_api_gateway_method.method"]
}

resource "aws_api_gateway_method_response" "400" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.api_resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "400"

  response_parameters {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models {
    "application/json" = "Error"
  }

  depends_on = ["aws_api_gateway_method.method"]
}

resource "aws_api_gateway_integration_response" "200" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.api_resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"

  response_parameters {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = ["aws_api_gateway_method.method", "aws_api_gateway_method_response.200"]
}

resource "aws_api_gateway_integration_response" "400" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.api_resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_method_response.400.status_code}"

  selection_pattern = ".+"

  response_parameters {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = <<EOF
#set($message = $util.escapeJavaScript($input.path('$.errorMessage')))
{
  "message": "$message"
}
EOF
  }

  depends_on = ["aws_api_gateway_method.method", "aws_api_gateway_method_response.400"]
}
