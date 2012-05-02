Name
====

svg2html\_image - SVG To HTML Image

Version
=======

0\.06

Synopsis
========

For using SVGs in HTML5 canvas.
Due to the restriction of the canvas implementation at current stage,
it's hard and also slow to draw all the SVG features into a canvas
by using canvas 2d context drawing command.

This library provides a convenient way to transform SVGs or
some fragments of SVGs into HTML Image objects and also
their bounding boxes when they are located in the SVGs.
We can use the canvas 2d context method **drawImage** to
put these SVGs into the canvas later.

Usage
=====

You can take a look on demo [here](http://cindylinz.github.com/Coffee-svg2html\_img/).

There's only one exported method **svg2html_image** with two form.

``` javascript
    // Get the canvas 2d context as normal
    var context = document.getElementsByTagName('canvas')[0].getContext('2d');

    // Form 1. Transform the whole SVG file into an Image
    svg2html_image(
        "/url/to/svg" or
        "<svg ...>" or
        "<?xml ...><svg ...>" or
        SVG_XML_object,
        function(image, bbox, svg){

            // Put the image to the left top corner (by reset the position of the bounding box)
            context.drawImage(image, -bbox.x, -bbox.y);

            // Put the 1/2 scaled version as the neighbor of the above one
            context.drawImage(image, bbox.width-bbox.x, -bbox.y, bbox.width/2, bbox.height/2);
        }
    );

    // Form 2. Transform the fragments of the SVG file
    svg2html_image(
        same_as_the_first_argument_as_form_1,
        [component_id_1, component_id_2, ...],
        function(array_of_image_and_bbox_and_svg){
            var i, image, bbox, svg;
            for(i=0; i<array_of_image_and_bbox_and_svg.length; ++i){
                image = array_of_image_and_bbox_and_svg[i][0];
                bbox = array_of_image_and_bbox_and_svg[i][1];
                svg = array_of_image_and_bbox_and_svg[i][2];

                // Act the same as form 1
            }
        }
    )
```

Install
=======

This library is written in [CoffeeScript][], and you can use it with or without [RequireJS][]
You can either:

+ If you are working with [RequireJS][], you can require this module by [cs][] plugin.

+ Compile the file svg2html\_image.coffee in lib/ into javascript file
  directly.

+ If you are not so familiar with [CoffeeScript][], you can use
  the [CoffeeScript][] interpreter like this:

``` html
    <script type="text/javascript" src="http://coffeescript.org/extras/coffee-script.js"></script>
    <script type="text/coffeescript" src="svg2html_image.coffee"></script>
```

  Notice that you should use the type **text/coffeescript** for the .coffee file.

[cs]: https://github.com/jrburke/require-cs
[CoffeeScript]: http://coffeescript.org/
[RequireJS]: http://requirejs.org/

Detailed API
============

svg2html\_image(svg, callback(image, bbox, extracted\_svg))
-------------------------------------------

  Transform the whole SVG file into an HTML Image object with its bounding box.
  If the SVG file specified its dimension, the generated HTML Image will be the same
  dimension as the SVG file, or the generated dimension will be chosen by the browser.

  The bounding box is not always identical to the SVG dimension,
  it's the bounding box of its content.

  Parameters:

  - svg:

    This parameter can be
    * SVG DOM object
    * SVG XML Document object
    * SVG XML Element object
    * URL string which lead to a remote SVG file
      (The SVG file should be located at the same domain, or the AJAX fetch will fail)
    * A string which with SVG XML format

    Although this parameter can be assigned with an isolated SVG node.
    You might get a weired result by this usage. Because this SVG node might need
    additional nodes such as gradients or patterns, and also its ancestor nodes
    which assigned inheritable attributes. You should use the second form of
    the method for this situation.

  - callback(image, bbox, extracted\_svg):

    When the image is created, the callback you provided will be called.
    the **image** is the Image object, and the **bbox** is an SVGRect object
    that point out the bounding box of the content elements.

    The additional **extrated\_svg** is a cloned SVG DOM element of the original SVG,
    you can insert this one into the HTML document directly if you need.

svg2html\_image(svg, array\_of\_ids, callback(array\_of\_images\_and\_bboxes\_and\_svg))
------------------------------------------------------------------------------

  The difference with the first form are the **array\_of\_ids** and the parameter for the **callback**.
  This form of the method will generates image object for each id.
  Not only the SVG node (and subtree) itself, but also its ancestor nodes and
  all the elements referenced by this subtree and their ancestor 
  and all the elements referenced by this forest and over and over again.
  So the visual effects should be preserved identical as they locates in the original SVG.

  - array\_of\_ids:

    Each element of **array\_of\_ids** is a string of the id value of an SVG element.
    If you use empty string as the id value, then this one will pick the whole SVG.

  - id syntax:

    The basic usage of **id** is just the id of the selected node.

    The extented usage (introduced in version 0.05) of **id** is to select
    a set of nodes which is consist of a series of positive ids and negative ids seperated by spaces.
    The negative ids is preceded by a minus sign (-).
    Then this library will create a image that consist of all the positive elements
    and exclude the negative ones.
    If there is no positive id at all, then the whole SVG is counted as the only positive element.

    For example:
    + 'a b c' // This image is consist of the three elements a, b, and c.
    + 'a -b c' // This image is consist of the two elements a and c, but exclude the b element if a or c contains it.
    + '' // This image is the whole SVG image.
    + '-a -b' // This image is the whole SVG image but the a and b elements.

    By the way, each id, positive or negative, could optionally has an astroid (*) at the end
    (introduced in version 0.06). This usage means to match any element that has this name as the prefix.

  - array\_of\_images\_and\_bboxes\_and\_svg:

    For each element in the **array\_of\_ids**, there will be an element in this array.
    Each of the result element is an array of 3 elements: **image**, **bbox** and **svg**.
    They are the same as in the first form.

License
=======

Copyright 2012, Cindy Wang (CindyLinz)  
Dual licensed under the MIT or GPL Version 2 licenses.

Date: 2012.5.2

