###

SVG To HTML Image Library v0.01
https://github.com/CindyLinz/Coffee-svg2html_img

Copyright 2012, Cindy Wang (CindyLinz)
Dual licensed under the MIT or GPL Version 2 licenses.

###

log = (msg) ->
    window.console.log(msg) if window.console?

ajax_load = (url, cb) ->
    req =
    if window.XMLHttpRequest
        new XMLHttpRequest()
    else if window.ActiveXObject
        try
            new ActiveXObject("Msxml2.XMLHTTP")
        catch e
            new ActiveXObject("Microsoft.XMLHTTP")
    else
        log("no ajax supported")

    unless req?
        cb(req)
        return

    req.onreadystatechange = () ->
        if req.readyState==4
            cb(req)

    req.open('GET', url)
    req.send(null)

base64_letter = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

utf8_encode = (input) ->
    return input.replace(/[^\x00-\x7F]/g, ($0) ->
        code = $0.charCodeAt(0)
        out = ''
        while code > 63
            out = String.fromCharCode(code & 63 | 128) + out
            code >>= 6
        switch out.length
            when 1
                return String.fromCharCode(code | 192) + out
            when 2
                return String.fromCharCode(code | 224) + out
            when 3
                return String.fromCharCode(code | 240) + out
            when 4
                return String.fromCharCode(code | 248) + out
            when 5
                return String.fromCharCode(code | 252) + out
    )

base64_encode = (input) ->
    out = ''
    for i in [0...input.length-2] by 3
        out += base64_letter.charAt( a = input.charCodeAt(i) >> 2 )
        out += base64_letter.charAt( b = ((input.charCodeAt(i)&3) << 4) | (input.charCodeAt(i+1) >> 4) )
        out += base64_letter.charAt( c = ((input.charCodeAt(i+1)&15) << 2) | (input.charCodeAt(i+2) >> 6) )
        out += base64_letter.charAt( d = input.charCodeAt(i+2)&63 )


    switch input.length % 3
        when 1
            out += base64_letter.charAt( input.charCodeAt(input.length-1) >> 2 )
            out += base64_letter.charAt( (input.charCodeAt(input.length-1)&3) << 4 )
            out += '=='
        when 2
            out += base64_letter.charAt( input.charCodeAt(input.length-2) >> 2 )
            out += base64_letter.charAt( ((input.charCodeAt(input.length-2)&3) << 4) | (input.charCodeAt(input.length-1) >> 4) )
            out += base64_letter.charAt( (input.charCodeAt(input.length-1)&15) << 2 )
            out += '='

    return out

node2text = (node) ->
    out = ''

    build = (node) ->
        unless node?
            return

        if node.nodeName == '#comment'
            return

        if node.nodeName == '#text'
            out += node.data
            return

        if node.nodeName.charAt(0) == '#'
            log "node2text: unimplemented dom node type #{node.nodeName}"
            return

        out += '<'
        out += node.nodeName

        for attr in node.attributes
            out += ' '
            out += attr.nodeName
            out += '="'
            out += attr.nodeValue.
                replace(/&/g, '&amp;').
                replace(/"/g, '&#34;')
            out += '"'

        if node.nodeName=='svg'
            out += ' xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'

        if node.hasChildNodes()
            out += '>'
            build(child) for child in node.childNodes
            out += '</'
            out += node.nodeName
            out += '>'
        else
            out += '/>'

    build(node)

    return out

build_image = (svg) ->
    return unless svg?
    doc = window.document
    doc.getElementsByTagName('body')[0].appendChild(svg)
    #log svg.getBBox()
    bbox = svg.getBBox()
    #alert "bbox = #{bbox.width}x#{bbox.height}+#{bbox.x}+#{bbox.y}"
    svg.parentNode.removeChild(svg)
    img = doc.createElement('img')
    img.style.position = 'absolute'
    img.style.visibility = 'hidden'
    img.style.left = '-9999px'
    img.style.top = '-9999px'
    if svg.getAttribute('width')? && svg.getAttribute('height')?
        img.style.width = svg.getAttribute('width')
        img.style.height = svg.getAttribute('height')
    #img.style.width = '1000px'
    #img.style.height = '666px'

    #log img.complete

    img.src = 'data:image/svg+xml;base64,' + base64_encode utf8_encode node2text svg
    #log img.complete
    #alert base64_encode utf8_encode node2text svg
    #img.src = 'svg_basic/chips.svg'

    doc.getElementsByTagName('body')[0].appendChild(img)

    return [img, bbox]

build_images = (svg, id_list, cb) ->

    build_id2node = (node, id2node) ->
        return id2node if node.nodeType==3 || node.nodeType==4

        if node.nodeType==1
            id = node.getAttribute('id')
            if id?
                if id2node[id]?
                    log "duplicated id: #{id}"
                id2node[id] = node

        build_id2node(child, id2node) for child in node.childNodes

        return id2node
    id2node = build_id2node(svg, {})

    find_dep = (node, dep_node) ->
        return dep_node if node.nodeName.charAt(0) == '#'

        for attr in node.attributes
            matches = attr.nodeValue.match(/#[^\s()]+/g)
            if matches?
                for match in matches
                    ref_id = match.substr(1)
                    if id2node[ref_id]?
                        unless dep_node[ref_id]?
                            dep_node[ref_id] = id2node[ref_id]
                            find_dep(id2node[ref_id], dep_node)

        find_dep(child, dep_node) for child in node.childNodes

        return dep_node

    extract_svg = (id) ->
        node =
        if id == ''
            svg
        else
            id2node[id]

        return node unless node?

        deps = find_dep(node, {})
        seeds = [node]
        for dep_id, dep_node of deps
            seeds.push(dep_node)

        for seed, i in seeds
            ptr = seed
            seeds[i] = [seed]
            while ptr!=svg && ptr.parentNode?
                ptr = ptr.parentNode
                seeds[i].unshift(ptr)

        do_clone = (node, depth, get_all) ->
            unless get_all
                take = no
                for seed in seeds
                    if seed[depth]==node
                        if depth==seed.length-1
                            get_all = yes
                        take = yes
                        break

                return unless take

            if node.nodeType==3 || node.nodeType==4
                return window.document.createTextNode(node.nodeValue)
            if node.nodeType==9 || node.nodeType==11
                for child in node.childNodes
                    cloned_child = do_clone(child, depth+1, get_all)
                    return cloned_child if cloned_child
            if node.nodeType!=1
                return

            cloned_node = window.document.createElementNS(node.namespaceURI, node.nodeName)
            for attr in node.attributes
                continue if attr.nodeName.match(/^xmlns\b/)
                cloned_node.setAttributeNS(attr.namespaceURI, attr.nodeName, attr.nodeValue)

            for child in node.childNodes
                cloned_child = do_clone(child, depth+1, get_all)
                cloned_node.appendChild(cloned_child) if cloned_child

            return cloned_node

        return do_clone(svg, 0, no)

    form1 =
    if id_list?
        no
    else
        id_list = ['']
        true

    done_one = () ->
        --waiting
        if waiting<=0
            window.setTimeout( () ->
                if form1
                    if imgs[0]?
                        cb(imgs[0]...)
                    else
                        cb(null, null)
                else
                    cb(imgs)
            , 0)

    waiting = id_list.length
    imgs =
    for id in id_list
        img_and_bbox = build_image extract_svg id
        if img_and_bbox?
            [img, bbox] = img_and_bbox
            img.onload = done_one
        else
            done_one()
        img_and_bbox

window.svg2html_image = (svg, id_list, cb) ->
    unless cb?
        cb = id_list
        id_list = undefined

    if typeof(svg)=='string'
        if svg.match(/^\s*</)
            xml =
            if window.DOMParser?
                parser = new DOMParser
                parser.parseFromString(svg, 'text/xml')
            else
                xml = new ActiveXObject('Microsoft.XMLDOM')
                xml.async = no
                xml.loadXML(svg.replace(/<!DOCTYPE svg[^>]*>/, ''))
                xml
            build_images(xml, id_list, cb)
        else
            ajax_load(svg, (req) ->
                success = yes

                unless req?
                    success = no

                if success && req.status!=200
                    log "fetch #{svg} fail: #{req.status}"
                    success = no

                if success && !req.responseXML
                    log "fetch #{svg} fail: not XML"
                    success = no

                if success && !req.responseXML.documentElement
                    log "fetch #{svg} fail: no documentElement"
                    success = no

                if success
                    build_images(req.responseXML.documentElement, id_list, cb)

                unless success
                    out = ( null for x in id_list )
                    cb(out)
            )
