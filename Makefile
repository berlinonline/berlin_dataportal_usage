# $BOSS_STATS needs to point at the location of the boss_extractor.rb script
# https://github.com/berlinonline/boss-stats

all: stats compress README.pdf

stats:
	@echo "generate stats"
	@ruby $$BOSS_STATS/boss_stats.rb conf/conf.json .

compress:
	@echo "compress daten_berlin_de.stats.json.tgz"
	@rm daten_berlin_de.stats.json.tgz
	@tar -cvzf daten_berlin_de.stats.json.tgz daten_berlin_de.stats.json

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