CHART := charts/redis
ENVS  := dev prod

.PHONY: validate
validate:
	@for e in $(ENVS); do \
	  helm lint $(CHART) -f $(CHART)/values-$$e.yaml || exit 1; \
	  helm template cache $(CHART) -f $(CHART)/values-$$e.yaml | kubeconform -strict -summary || exit 1; \
	done
	@if helm lint $(CHART) --set image.tag=latest >/dev/null 2>&1; then \
	  echo "schema should reject image.tag=latest"; exit 1; fi
