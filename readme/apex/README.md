

## Forms

Don't forget that rowid and pk columns will prevent form from loading
when you set pk and rowid col exists. Took a while to figure out 
I needed to delete the rowid col to get the form to load during 
the init process after pk value has been set.