OUT_FOLDER=data/current

all: json_stats csv_stats compress README.pdf

json_stats:
	@echo "generate JSON stats"
	@python bin/extract_stats.py

csv_stats: json_stats
	@echo "generate CSV stats (totals only)"
	@python bin/json2csv.py

compress:
	@echo "compress daten_berlin_de.stats.json.tgz"
	@rm -f ${OUT_FOLDER}/daten_berlin_de.stats.json.tgz
	@tar -cvzf ${OUT_FOLDER}/daten_berlin_de.stats.json.tgz ${OUT_FOLDER}/daten_berlin_de.stats.json

README.pdf: README.md
	@echo "generate README.pdf from README.md"
	@pandoc -o README.pdf README.md

README.md: date.txt
	@echo "update README.md with current date"
	@sed '$$ d' README.md > _README.md
	@cat _README.md date.txt > README.md
	@rm _README.md date.txt

date.txt:
	@echo "write current date"
	@date "+Last changed: %Y-%m-%d" > date.txt

.PHONY: README.md date.txt compress

# individual datasets

data/report/%.json: data/current/daten_berlin_de.stats.json
	jq --arg page "$*" \
	'.stats.pages.datensaetze.sub_page_counts | \
	with_entries(select(.value[$$page]) | \
	.value = .value[$$page])' $< > $@

data/report/%.csv: data/report/%.json
	cat $< | jq -r 'to_entries \
	| (["month","impressions","visits"] | @csv), (.[] | \
	[.key, .value.impressions, .value.visits] | @csv)' > $@