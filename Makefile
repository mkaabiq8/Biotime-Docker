.PHONY: init preflight deploy publish status logs backup

init:
	./scripts/init-config.sh

preflight:
	./scripts/preflight.sh

deploy:
	./scripts/deploy.sh

publish:
	./scripts/publish.sh

status:
	./scripts/status.sh

logs:
	./scripts/logs.sh

backup:
	./scripts/backup.sh

