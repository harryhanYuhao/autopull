all:

install:
	mkdir -p ~/.local/bin/
	cp ./autopull.sh ~/.local/bin/autopull 
	chmod +x ~/.local/bin/autopull

test:
	rm -rf ~/.cache/autopull/*
	./autopull.sh ~/study/scol
