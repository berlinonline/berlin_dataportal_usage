OUT_FOLDER=data/current

all: stats compress README.pdf

stats:
	@echo "generate stats"
	@ruby bin/extract_stats.rb conf/stat_settings.json ${OUT_FOLDER}

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