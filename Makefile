workshop: workshop.Rmd
	./make_slides workshop

solutions: solutions.md
	pandoc -s --webtex -t slidy solutions.md -o solutions.html --self-contained
