
Web API
-------

I am currently running the Irish standardizer and the gd2ga and gv2ga
translators as a web service which powers several applications:

* the Intergaelic web site <http://intergaelic.com/>
* Twitter streams <http://borel.slu.edu/gd2ga> and <http://borel.slu.edu/gv2ga>
* [Minority Translate](http://translate.keeleleek.ee/wiki/Esileht), a translation application for Wikipedia articles
* [Pootle](http://pootle.translatehouse.org/), web-based localization server
* [Command line clients](https://github.com/kscanne/caighdean/tree/master/clients) in Perl, Python, Ruby, and more

To use the API, simply make a HTTP POST request to the URL
`http://borel.slu.edu/cgi-bin/seirbhis3.cgi` (https works too)
with two parameters:

* `teacs`: The source text to be translated, UTF-8 encoded
* `foinse`: The ISO 639-1 code of the source language ("ga", "gd" or "gv"). Specifying source language "ga" invokes the Irish standardizer.  Currently, Irish (ga) is the only supported target language so it does not get specified as a parameter.

The response will be a JSON array of _translation pairs_.  For example,
if the value of the `foinse` parameter is "gd" (Scottish Gaelic), and
the value of the `teacs` parameter is the following string (containing an embedded newline):

```
Agus thubhairt e,
"Iongantach!" an dèidh sin.
```

You should get the following response:

```json
[["Agus","Agus"],["thubhairt","dúirt"],["e","sé"],[",",","],["\\n","\\n"],["\"","\""],["Iongantach","Iontach"],["!","!"],["\"","\""],["an dèidh sin","ina dhiaidh sin"],[".","."]]
```

How you process the JSON depends on the application you have in mind.
If you are only interested in the target language translation, you can
simply extract the second element of each pair and concatenate them
together (there is a very simple detokenizer included in this repo). 
But since the languages we support are linguistically very close, in most
cases we expect it to be more interesting and useful to use the
translations as _annotations_ of one kind or another on the source text,
as was done with Intergaelic and the Twitter streams.

Having the full set of translation pairs may also make it easier to 
carry over any markup from the source text to the target text.

Details
-------

* Generally speaking, texts are tokenized into single words, but occasionally
a translation pair will have more than one word on the source side, as
in the example above (_an dèidh sin_). Similarly, there may be multiple
words on the target side of a translation pair.
* There is no guarantee that the number of words on the target side
of a translation pair will be the same as the number on the source side.
It is important to keep this in mind if designing an application that
aligns source to target in some way.
* The translator treats SGML markup, URLs, email addresses and so on as
single tokens, and passes them through unchanged.
* The web service supports [CORS requests](http://enable-cors.org/).

HTTP Response Codes
-------------------

* 200 (OK): Successful request
* 400 (Bad Request): Missing parameter in request, unsupported source language, empty source text, source text not encoded as UTF-8, etc.
* 403 (Forbidden): Request from unapproved IP address
* 405 (Method Not Allowed): Only POST requests permitted
* 413 (Payload Too Large): Request larger than 16k bytes
* 500 (Internal Server Error): Translation server failed to process request

Rate Limits
-----------

Since these are pretty low-traffic web sites, I am not currently placing
any rate limits on requests to the API.  Individual requests are capped
at 16k bytes.  I would appreciate an email (kscanne at gmail) if you build
something interesting or useful in any case, and especially so if you expect
to be making many requests.
