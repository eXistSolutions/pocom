xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace frus="http://history.state.gov/frus/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

declare function local:wrap-html($title, $body, $q, $sort) {
    <html lang="en">
        <head>
            <!-- Required meta tags -->
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
            
            <!-- Bootstrap CSS -->
            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"/>
            <style type="text/css">
                body {{ font-family: HelveticaNeue, Helvetica, Arial, sans; }}
                table {{ page-break-inside: avoid; }}
                .missing-target {{ text-decoration-line: underline; text-decoration-style: dashed; }}
                .highlight {{ background-color: yellow }}
                .form-check {{ justify-content: left !important }}
                dt {{
                    float: left;
                    clear: left;
                    width: 10em;
                    text-align: right;
                }}
                dt::after {{
                    content: ":";
                }}
                dd {{
                    margin: 0 0 0 11em;
                    padding: 0 0 0.5em 0;
                }}
            </style>
            <style type="text/css" media="print">
                a, a:visited {{ text-decoration: underline; color: #428bca; }}
                a[href]:after {{ content: ""; }}
            </style>
            <title>{$title}</title>
        </head>
        <body>
            <div class="container-fluid">
                <h3><a href="/exist/apps/pocom/modules/facets-chiefs.xq">POCOM Chiefs</a></h3>
                <form class="form-inline" action="?" method="get">
                    <div class="form-group">
                        <label for="q" class="control-label mb-2 mr-2">Search POCOM Chiefs</label>
                        <input type="text" name="q" id="q" class="form-control mb-2 mr-2" value="{$q}"/>
                        <label for="sort-country" class="control-label mb-2 mr-2">Sort by country</label>
                        <input type="radio" name="sort" id="sort-country" class="form-control mb-2 mr-2" value="country"/>{if ($sort eq "country" or $sort eq "") then attribute checked { "checked" } else ()}
                        <label for="sort-date" class="control-label mb-2 mr-2">by date</label>
                        <input type="radio" name="sort" id="sort-date" class="form-control mb-2 mr-2" value="date"/>{if ($sort eq "date") then attribute checked { "checked" } else ()}
                    </div>
                    <button type="submit" class="btn btn-primary mb-2 mr-2">Submit</button>
                    { if (request:get-query-string() ne "") then <a class="btn btn-secondary mb-2 mr-2" href="{request:get-url()}">Reset</a> else () }
                    {$body}
                </form>
            </div>
            
            <!-- jQuery first, then Popper.js, then Bootstrap JS -->
            <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
            <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
        </body>
    </html>
};
declare function local:results-to-list($q, $facet-query, $query-hits, $facet-results as array(*)?, $facet-prefs as map(*)+, $start, $per-page, $sort) {
    <div class="row">
        <div class="col col-2">
            <h3>Facets</h3>
            {
            if (array:size($facet-results) gt 1) then
                array:for-each(
                    $facet-results, 
                    function($result) {
                        let $facet-name := map:keys($result)
                        let $facet := $facet-prefs[?name eq $facet-name]
                        let $is-hierarchical := $facet?hierarchical 
                        let $is-hierarchical-request := $is-hierarchical and exists($facet?request)
                        return
                            <fieldset class="form-group">
                                <h4>{$facet?label, " ", <small>{
                                let $max := if ($facet?max eq 10) then -1 else 10 
                                return
                                    <a href="{request:get-url() || (if (request:get-query-string() ne "") then ("?" || replace(request:get-query-string(), "&amp;?" || $facet-name || "-max=-?\d+", "") || "&amp;") else "?") || $facet-name || "-max=" || $max}">{if ($max eq -1) then "Show all" else "Limit to top 10"}</a>
                                , if ($facet?hierarchical) then " [hierarchical]" else ()}</small>}</h4>
                                {
                                    if ($is-hierarchical) then
                                        for $request at $n in $facet?request
                                        let $id := $facet-name || "-hierarchical-" || $n
                                        return
                                            <div class="form-check">
                                                {
                                                    if ($is-hierarchical-request) then 
                                                        attribute style { "padding-left: " || $n - 1 || "em" } 
                                                    else 
                                                        ()
                                                }
                                                <input class="form-check-input" type="checkbox" checked="checked" id="{$id}" name="{$facet-name}" value="{$request}"/>
                                                <label class="form-check-label" for="{$id}">{$request}</label>
                                            </div>
                                    else
                                        (),
                                    <div>{
                                        if ($is-hierarchical-request) then 
                                            attribute style { "padding-left: " || count($facet?request) || "em" } 
                                        else 
                                            (),
                                        for $value at $n in $result?*?*
                                        let $name := map:keys($value)
                                        let $id := $facet-name || "-" || $n
                                        let $count := format-number($value?*, "#,###.##")
                                        let $is-checked := if ($is-hierarchical-request) then () else $facet-query?facets($facet-name) = $name
                                        return
                                            <div class="form-check">
                                                <input class="form-check-input" type="{if ($is-hierarchical) then "radio" else "checkbox"}" id="{$id}" name="{$facet-name}" value="{$name}"/>
                                                {if ($is-checked) then attribute checked { "checked" } else () }
                                                <label class="form-check-label" for="{$id}">{$name} ({$count})</label>
                                            </div>
                                    }</div>
                                }
                            </fieldset>
                    }
                )
            else
                ()
            }
            <button type="submit" class="btn btn-secondary">Apply Filters</button>
        </div>
        <div class="col col-10">
            <h2>Results</h2>
            <p>{$start}–{min((count($query-hits), $start + $per-page - 1))} of { 
                if ($q or map:size($facet-query?facets) ge 1) then 
                    format-number(count($query-hits), "#,###.##") || " hits for documents with "
                else 
                    "all " || format-number(count($query-hits), "#,###.##") || " documents",
                string-join(
                    (
                        if ($q) then "keyword “" || $q || "”" else (),
                        map:for-each($facet-query?facets, function($key, $values) { 
                            let $facet := $facet-prefs[?name eq $key]
                            let $facet-label := $facet?label
                            return
                                lower-case($facet-label) || " of " || 
                                    (
                                        if ($facet?hierarchical) then
                                            ( "“" || string-join($values, " › ") || "”" )
                                        else
                                            string-join($values ! ("“" || . || "”"), ", ")
                                    )
                           }
                       )
                    ),
                    "; "
                )[. ne ""]
            }.</p>
            {
            let $nav := <nav aria-label="Page navigation">
                <ul class="pagination">{
                    if ($start gt $per-page) then 
                        <li class="page-item"><a class="page-link" href="{request:get-url() || (if (request:get-query-string() ne "") then ("?" || replace(request:get-query-string(), "&amp;?start=\d+", "") || "&amp;") else "?") || "start=" || $start - $per-page}">Previous</a></li>
                    else
                        (),
                    if (count($query-hits) gt $start + $per-page) then 
                        (
                            <li class="page-item"><a class="page-link" href="{request:get-url() || (if (request:get-query-string() ne "") then ("?" || replace(request:get-query-string(), "&amp;?start=\d+", "") || "&amp;") else "?") || "start=" || $start + $per-page}">Next</a></li>,
                            <li class="page-item"><a class="page-link" href="{request:get-url() || (if (request:get-query-string() ne "") then ("?" || replace(request:get-query-string(), "&amp;?start=\d+", "") || "&amp;") else "?") || "per-page=" || count($query-hits)}">All</a></li>
                        )
                    else 
                        ()
                }</ul>
            </nav>
            return 
                if ($nav//li) then 
                    $nav
                else
                    ()
            }
            <table class="table">
                <thead>
                    <tr>
                        <th>No.</th>
                        <th>Name</th>
                        <th>Title</th>
                        <th>Country</th>
                        <th>Appointed</th>
                        <th>Started</th>
                        <th>Ended</th>
                    </tr>
                </thead>
                {
                    let $ordered-hits := 
                        if ($sort eq "date") then
                            for $hit in $query-hits
                            order by ($hit//date[. ne ''][1], $hit/preceding::date[. ne ''][1], $hit/following::date[. ne ''][1])[1]
                            return $hit                            
                        else (: if ($sort eq "country") :)
                            for $hit in $query-hits
                            order by $hit/ancestor::country-mission/territory-id
                            return $hit
                    let $hits-to-show := $ordered-hits => subsequence($start, $per-page)
                    for $hit at $n in $hits-to-show
                    let $person-id := $hit/person-id
                    let $role-title-id := $hit/role-title-id
                    let $territory-id := $hit/ancestor::country-mission/territory-id
                    let $appointed := $hit/appointed
                    let $started := $hit/started
                    let $ended := $hit/ended
                    return
                        <tr>
                            <td>{$start + $n - 1}</td>
                            <td>{ft:field($hit, "name")}</td>
                            <td>{ft:field($hit, "title")}</td>
                            <td>{$territory-id/string()}</td>
                            <td>{local:format-date($appointed/date), if ($appointed/note ne "") then (<br/>, $appointed/note/string()) else ()}</td>
                            <td>{local:format-date($started/date)}</td>
                            <td>{local:format-date($ended/date)}</td>
                        </tr>
                }
            </table>
        </div>
    </div>
};

declare function local:format-date($date as xs:string) {
    if ($date eq "") then ()
    else if (matches($date, "^\d{4}$")) then $date
    else if (matches($date, "^\d{4}-\d{2}$")) then format-date(xs:date($date || "-01"), "[MNn,*-3] [Y]")
    else format-date(xs:date($date), "[MNn,*-3] [D], [Y]")
};

let $q := request:get-parameter("q", ())[. ne ""]
let $start := request:get-parameter("start", 1) cast as xs:integer
let $per-page := request:get-parameter("per-page", 25) cast as xs:integer
let $sort := request:get-parameter("sort", "country")
let $default-facets-max := request:get-parameter("facets-max", 10) cast as xs:integer

let $person-ids := request:get-parameter("person-id", ())[. ne ""]
let $territory-ids := request:get-parameter("territory-id", ())[. ne ""]
let $role-title-ids := request:get-parameter("role-title-id", ())[. ne ""]
let $appointment-date := request:get-parameter("appointment-date", ())[. ne ""]
let $start-date := request:get-parameter("start-date", ())[. ne ""]
let $end-date := request:get-parameter("end-date", ())[. ne ""]

let $person-ids-max := request:get-parameter("person-id-max", $default-facets-max) cast as xs:integer
let $territory-ids-max := request:get-parameter("territory-id-max", $default-facets-max) cast as xs:integer
let $role-title-ids-max := request:get-parameter("role-title-id-max", $default-facets-max) cast as xs:integer
let $appointment-date-max := request:get-parameter("appointment-date-max", $default-facets-max) cast as xs:integer
let $start-date-max := request:get-parameter("start-date-max", $default-facets-max) cast as xs:integer
let $end-date-max := request:get-parameter("end-date-max", $default-facets-max) cast as xs:integer

let $facet-query :=
    map { 
        "facets":
            map:merge((
                if (exists($person-ids)) then map:entry("person-id", $person-ids) else (),
                if (exists($territory-ids)) then map:entry("territory-id", $territory-ids) else (),
                if (exists($role-title-ids)) then map:entry("role-title-id", $role-title-ids) else (),
                if (exists($appointment-date)) then map:entry("appointment-date", $appointment-date) else (),
                if (exists($start-date)) then map:entry("start-date", $start-date) else (),
                if (exists($end-date)) then map:entry("end-date", $end-date) else ()
            )),
        "fields": ("name", "title")
    }
let $query-hits := collection("/db/apps/pocom")//chief[ft:query(., $q, $facet-query)][ancestor::country-mission]
let $facet-prefs := 
    (
        map {
            "name": "person-id",
            "label": "Person ID",
            "max": $person-ids-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": false(),
            "request": $person-ids
        },
        map {
            "name": "territory-id",
            "label": "Territory ID",
            "max": $territory-ids-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": false(),
            "request": $territory-ids
        },
        map {
            "name": "role-title-id",
            "label": "Role Title ID",
            "max": $role-title-ids-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": false(),
            "request": $role-title-ids
        },
        map {
            "name": "appointment-date",
            "label": "Appointment Date",
            "max": $appointment-date-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": true(),
            "request": $appointment-date
        },
        map {
            "name": "start-date",
            "label": "Start Date",
            "max": $start-date-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": true(),
            "request": $start-date
        },
        map {
            "name": "end-date",
            "label": "End Date",
            "max": $end-date-max,
            "sort": "value",
            "order": "ascending",
            "hierarchical": true(),
            "request": $end-date
        }
    )
let $facet-results :=
    array { 
        if ($query-hits) then 
            for $facet in $facet-prefs
            let $values := 
                if ($facet?max eq -1) then 
                    ft:facets(head($query-hits), $facet?name) 
                else if ($facet?hierarchical and exists($facet?request)) then 
                    ft:facets(head($query-hits), $facet?name, $facet?max, $facet?request) 
                else 
                    ft:facets(head($query-hits), $facet?name, $facet?max)
            return
                map:entry($facet?name, 
                    array { 
                        if ($facet?sort eq "value" and $facet?order eq "ascending") then
                            for $key in map:keys($values)
                            let $value := map:get($values, $key)
                            order by $key ascending
                            return
                                map { $key: $value }
                        else if ($facet?sort eq "value" and $facet?order eq "descending") then
                            for $key in map:keys($values)
                            let $value := map:get($values, $key)
                            order by $key descending
                            return
                                map { $key: $value }
                        else if ($facet?sort eq "count" and $facet?order eq "ascending") then
                            for $key in map:keys($values)
                            let $value := map:get($values, $key)
                            order by $value ascending
                            return
                                map { $key: $value }
                        else if ($facet?sort eq "count" and $facet?order eq "descending") then
                            for $key in map:keys($values)
                            let $value := map:get($values, $key)
                            order by $value descending
                            return
                                map { $key: $value }
                        else (: unordered :)
                            for $key in map:keys($values)
                            let $value := map:get($values, $key)
                            return
                                map { $key: $value }
                    }
                )
        else 
            ()
    }
let $content := local:results-to-list($q, $facet-query, $query-hits, $facet-results, $facet-prefs, $start, $per-page, $sort)
let $title := "Facets"
return
    local:wrap-html($title, $content, $q, $sort)