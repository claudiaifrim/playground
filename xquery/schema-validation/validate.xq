xquery version "3.1" encoding "utf-8";

declare namespace schemaValidate = 'schemaValidate';
declare namespace validate = 'http://basex.org/modules/validate';
declare namespace functx = "http://www.functx.com";

declare variable $source_url external;


declare function schemaValidate:css() as element()* {
    <style>
        <![CDATA[
pre.iedreg { display: inline }
div.iedreg { box-sizing: border-box; font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; font-size: 14px; color: #333 }
div.iedreg.header { font-size: 16px; font-weight: 500; margin: 0.8em 0 0.4em 0 }
div.iedreg.table { display: table; width: 100%; border-collapse: collapse; }
div.iedreg.row { display: table-row; word-break: break-word;}
div.iedreg.col {
    min-width: 100px;
    display: table-cell;
    padding: 0.4em;
    border: 1pt solid #aaa
}
div.iedreg.col message {
    display: block;
}
div.iedreg.inner {
    //width: 90%;
    //margin-left: 2%;
    margin-top: 0.4em;
    margin-bottom: 0.6em
}
div.iedreg.outer { padding-bottom: 0; border: 1pt solid #888 }
div.iedreg.inner { border: 1pt solid #aaa }
div.iedreg.parent { margin-bottom: 1.5em }
div.iedreg.th { border-bottom: 2pt solid #000; font-weight: 600 }
div.iedreg.blocker { background-color: #fdf7f7; border-bottom: 2pt solid #d9534f }
div.iedreg.warning { background-color: #faf8f0; border-bottom: 2pt solid #f0ad4e }
div.iedreg.info { background-color: #f4f8fa; border-bottom: 2pt solid #5bc0de }
div.iedreg.red { background-color: #fdf7f7; color: #b94a48 }
div.iedreg.yellow { background-color: #faf8f0; color: #8a6d3b }
div.iedreg.blue { background-color: #f4f8fa; color: #34789a }
div.iedreg.gray { background-color: #eee; color: #555 }
div.iedreg.msg { margin-top: 1em; margin-bottom: 1em; padding: 1em 2em }
div.iedreg.msg.mblocker { 
    border-color: #d9534f; 
    background-color: #fdf7f7; color: #b94a48 
}
div.iedreg.msg.mok { 
    border-color: #5cb85c; 
    background-color: #e6fbe6; color: #098b09 
}
div.iedreg.msg.mwarning { border-color: #f0ad4e }
div.iedreg.msg.minfo { border-color: #5bc0de }
div.iedreg.msg.mnone { border-color: #ccc }
div.iedreg.nopadding { padding: 0 }
div.iedreg.nomargin { margin: 0 }
div.iedreg.noborder { border: 0 }
div.iedreg.left { text-align: left }
div.iedreg.center { text-align: center }
div.iedreg.right { text-align: right }
div.iedreg.top { vertical-align: top }
div.iedreg.middle { vertical-align: middle }
div.iedreg.bottom { vertical-align: bottom }
div.iedreg.ten { width: 10%; }
div.iedreg.quarter { width: 25%; }
div.iedreg.half { width: 50%; }
input[type=checkbox].iedreg { display:none }
input[type=checkbox].iedreg + div.iedreg { display:none }
input[type=checkbox].iedreg:checked + div.iedreg { display: block }
span.iedreg { display:inline-block }
span.iedreg.nowrap {
    white-space: nowrap
}
span.iedreg.break {
    word-wrap: break-word
}
span.iedreg.top { vertical-align: top}
span.iedreg.link { cursor: pointer; cursor: hand; text-decoration: underline }
span.iedreg.big { padding: 0.1em 0.9em }
span.iedreg.medium { padding: 0.1em 0.5em }
span.iedreg.small { padding: 0.1em }
span.iedreg.header { display: block; font-size: 16px; font-weight: 600 }
span.iedreg.failed { color: #fff; background-color: #000000 }
span.iedreg.blocker { color: #fff; background-color: #d9534f }
span.iedreg.warning { color: #fff; background-color: #f0ad4e }
span.iedreg.info { color: #fff; background-color: #5bc0de }
span.iedreg.pass { color: #fff; background-color: #5cb85c }
span.iedreg.none { color: #fff; background-color: #999 }
ul.iedreg.error-summary {margin: 0}

]]>
    </style>
};


declare function functx:substring-before-last-match
($arg as xs:string?,
        $regex as xs:string) as xs:string? {

    replace($arg, concat('^(.*)', $regex, '.*'), '$1')
};
declare function functx:is-node-in-sequence
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies $nodeInSeq is $node
 } ;
declare function functx:distinct-nodes
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence(
                                .,$nodes[position() < $seq]))]
 } ;

declare function schemaValidate:validate($source_url as xs:string){
    (: let $envelopeURL := functx:substring-before-last-match($source_url, '/') || '/xml' :)
    let $envelopeURL := $source_url
    let $envelopeDoc := fn:doc($envelopeURL)
    let $files := $envelopeDoc//*
    let $hdrs := ("Validation result", "File name", "File url")

    let $results := 
        for $file in $files
            let $fileName := $file/@name/data()
            let $fileUrl := $file/@link/data()
            let $fileType := $file/@type/data()

            where $fileType = 'text/xml'
            where fn:ends-with($fileName, '.xml') || fn:ends-with($fileName, '.gml')

            let $file_source_url := fn:concat('source_url=',$fileUrl)
            let $fileX := fn:replace($source_url,'source_url=.*',$file_source_url)

            let $validationResult := validate:xsd-report($fileX)
            let $resultDistinct := 
                for $message in distinct-values($validationResult/*)
                    return <message>{$message}</message>

            let $validStatus := $validationResult//*:status/data()
            let $validMessage := $validationResult//*:message/data()
            let $errorType := if($validStatus = 'valid')
                then 'pass'
                else 'blocker'

            return 
                <div class="iedreg row">
                    <div class="iedreg col inner {$errorType}">{$resultDistinct}</div>
                    <div class="iedreg col inner">{$fileName}</div>
                    <div class="iedreg col inner">{$fileUrl}</div>
                </div>

    let $all := $results//@class[starts-with(., 'iedreg col inner')]/string()
    let $all := for $i in $all return tokenize($i, "\s+")
    let $status :=
            if ($all = "failed") then "failed"
            else if ($all = "blocker") then "blocker"
            else if ($all = "pass" or empty($all)) then "ok"
            else ""

    let $feedbackMessage :=
        if ($status = "failed") then
            "QA failed to execute."
        else if ($status = "blocker") then
            "QA completed but there were blocking errors."
        else if ($status = "ok") then
            "QA completed without errors"
        else
            "QA status is unknown"

    return 
        if($results) then
        <div class="feedbacktext">
            <span id="feedbackStatus" class="{$status => upper-case()}" style="display:none">{$feedbackMessage}</span>
            <div class="iedreg table parent">
                {schemaValidate:css()}
                <div class="iedreg row">
                    <div class="iedreg col outer noborder">
                        <!-- report table -->
                        <div class="iedreg table">
                            <div class="iedreg">
                                <div class="iedreg inner msg m{$status}">{$feedbackMessage}</div>
                                <div class="iedreg table inner">
                                    <div class="iedreg row">
                                        {for $h in $hdrs
                                        return
                                            <div class="iedreg col inner th"><span class="iedreg break">{$h}</span></div>
                                        }
                                    </div>
                                    {$results}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        else
        
        <div class="feedbacktext">
            <span id="feedbackStatus" class="{$status => upper-case()}" style="display:none">{$feedbackMessage}</span>
            <div class="iedreg table parent">
                {schemaValidate:css()}
                <div class="iedreg row">
                    <div class="iedreg col outer noborder">
                        <!-- report table -->
                        <div class="iedreg table">
                            <div class="iedreg">
                                <div class="iedreg inner msg m{$status}">{$feedbackMessage}</div>
                                <em>There are no .xml or .gml files in the envelope</em>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
};

schemaValidate:validate($source_url)
