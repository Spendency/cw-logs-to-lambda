SHELL := /bin/sh
PY_VERSION := 3.7

export PYTHONUNBUFFERED := 1

SRC_DIR := src
SAM_DIR := .aws-sam

# Required environment variables (user must override)

# S3 bucket used for packaging SAM templates
PACKAGE_BUCKET ?= spendency-package-prod
#dev PACKAGE_BUCKET ?= spendency-package

# user can optionally override the following by setting environment variables with the same names before running make

# Path to system pip
PIP ?= pip
# Default AWS CLI region
AWS_DEFAULT_REGION ?= eu-west-1
STACK_NAME ?= logs-to-lambda
FUNCTION_NAME ?= lambda-to-slack-LambdaToSlack-14ZVNRXCCCR5J
#dev FUNCTION_NAME ?= lambda-to-slack-LambdaToSlack-167WEN21S6RRX
LOG_GROUP_NAME ?= "/var/log/tomcat8/spendency.log"
FILTER_PATTERN ?= '"ERROR" - "Two suppliers have the same"'

PYTHON := $(shell /usr/bin/which python$(PY_VERSION))

.DEFAULT_GOAL := build
.PHONY: test clean undeploy deploy package compile build publish bootstrap init

clean:
	rm -f $(SRC_DIR)/requirements.txt
	rm -rf $(SAM_DIR)

# used once just after project creation to lock and install dependencies
bootstrap:
	$(PYTHON) -m $(PIP) install pipenv --user
	pipenv lock
	pipenv sync --dev

# used by CI build to install dependencies
init:
	$(PYTHON) -m $(PIP) install pipenv --user
	pipenv sync --dev

test:
	pipenv run flake8 $(SRC_DIR)
	pipenv run pydocstyle $(SRC_DIR)
	pipenv run cfn-lint template.yml
	#pipenv run py.test --cov=$(SRC_DIR) --cov-fail-under=90 -vv test/unit

compile: test
	pipenv lock --requirements > $(SRC_DIR)/requirements.txt
	pipenv run sam build

build: compile

package: compile
	pipenv run sam package --s3-bucket $(PACKAGE_BUCKET) --output-template-file $(SAM_DIR)/packaged-template.yml

deploy: package
	pipenv run sam deploy --template-file $(SAM_DIR)/packaged-template.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides DestinationFunctionName=${FUNCTION_NAME} LogGroupName=${LOG_GROUP_NAME} FilterPattern=${FILTER_PATTERN}

# used to delete the cfn stack
undeploy:
	pipenv run aws cloudformation delete-stack --stack-name $(STACK_NAME)

publish: package
	pipenv run sam publish --template $(SAM_DIR)/packaged-template.yml
