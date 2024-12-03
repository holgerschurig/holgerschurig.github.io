all:
	for i in `find -name "*.org"`; do \
		echo "--> $$i"; \
		emacsclient -e "(progn (find-file \"$$i\") (beginning-of-buffer) (search-forward \":end:\") (org2hugo))"; \
	done

