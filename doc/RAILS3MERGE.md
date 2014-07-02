Notes 2014-06-23:

1. any calls to set_content need to be checked --- either use set_xml_content or add actor info to options. Need to investigate what actor needs to be set to.

2. perseus epidoc stylesheets are not compiling. might be due to discrepancies between version of default epidoc xslt templates referenced from them in this branch the the version used in perseus_shibboleth

Notse 2014-07-01:

1. Left off with failure on retrieval of sentence from treebank file - to investigate

2. need to html_safe all transforms which bring xml/html into the display

3. need to cleanup setup of exist application tools template html files for paths
