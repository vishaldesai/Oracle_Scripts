store set sqlplus_settings.bak replace

accept owner   prompt 'Enter schema owner    : '

SET TERMOUT ON


SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
PRO

SPO logs\er.html;

PRO <!doctype html>
PRO <html>
PRO <head>
PRO <title>Entity Relationship</title>
PRO 
PRO <script src="go.js"></script>
PRO 
PRO <script id="code">
PRO   function init() {
PRO     //if (window.goSamples) goSamples();  // init for these samples -- you don't need to call this
PRO     var $ = go.GraphObject.make;  // for conciseness in defining templates
PRO 
PRO     myDiagram =
PRO       $(go.Diagram, "myDiagram",  // must name or refer to the DIV HTML element
PRO         {
PRO           initialContentAlignment: go.Spot.Center,
PRO           allowDelete: true,
PRO           allowCopy: true,
PRO           layout: $(go.ForceDirectedLayout),
PRO           "undoManager.isEnabled": true
PRO         });
PRO 
PRO     // define several shared Brushes
PRO     var bluegrad = $(go.Brush, go.Brush.Linear, { 0: "rgb(150, 150, 250)", 0.5: "rgb(86, 86, 186)", 1: "rgb(86, 86, 186)" });
PRO     var greengrad = $(go.Brush, go.Brush.Linear, { 0: "rgb(158, 209, 159)", 1: "rgb(67, 101, 56)" });
PRO     var redgrad = $(go.Brush, go.Brush.Linear, { 0: "rgb(206, 106, 100)", 1: "rgb(180, 56, 50)" });
PRO     var yellowgrad = $(go.Brush, go.Brush.Linear, { 0: "rgb(254, 221, 50)", 1: "rgb(254, 182, 50)" });
PRO     var lightgrad = $(go.Brush, go.Brush.Linear, { 1: "#E6E6FA", 0: "#FFFAF0" });
PRO 
PRO     var itemTempl =
PRO       $(go.Panel, "Horizontal",
PRO         $(go.Shape,
PRO           { desiredSize: new go.Size(10, 10) },
PRO           new go.Binding("figure", "figure"),
PRO           new go.Binding("fill", "color")),
PRO         $(go.TextBlock,
PRO           { stroke: "#333333",
PRO             font: "bold 14px sans-serif" },
PRO           new go.Binding("text", "name"))
PRO       );
PRO 
PRO     // define the Node template, representing an entity
PRO     myDiagram.nodeTemplate =
PRO       $(go.Node, "Auto",  // the whole node panel
PRO         { selectionAdorned: true,
PRO           resizable: true,
PRO           layoutConditions: go.Part.LayoutStandard & ~go.Part.LayoutNodeSized,
PRO           fromSpot: go.Spot.AllSides,
PRO           toSpot: go.Spot.AllSides,
PRO           isShadowed: true,
PRO           shadowColor: "#C5C1AA" },
PRO         new go.Binding("location", "location").makeTwoWay(),
PRO         // define the nodes outer shape, which will surround the Table
PRO         $(go.Shape, "Rectangle",
PRO           { fill: lightgrad, stroke: "#756875", strokeWidth: 3 }),
PRO         $(go.Panel, "Table",
PRO           { margin: 8, stretch: go.GraphObject.Fill },
PRO           $(go.RowColumnDefinition, { row: 0, sizing: go.RowColumnDefinition.None }),
PRO           // the table header
PRO           $(go.TextBlock,
PRO             {
PRO               row: 0, alignment: go.Spot.Center,
PRO               margin: new go.Margin(0, 14, 0, 2),  // leave room for Button
PRO               font: "bold 16px sans-serif"
PRO             },
PRO             new go.Binding("text", "key")),
PRO           // the collapse/expand button
PRO           $("Button",
PRO             {
PRO               row: 0, alignment: go.Spot.TopRight,
PRO               "ButtonBorder.stroke": null,
PRO               click: function(e, but) {
PRO                 var list = but.part.findObject("LIST");
PRO                 if (list !== null) {
PRO                   list.diagram.startTransaction("collapse/expand");
PRO                   list.visible = !list.visible;
PRO                   var shape = but.findObject("SHAPE");
PRO                   if (shape !== null) shape.figure = (list.visible ? "TriangleUp" : "TriangleDown");
PRO                   list.diagram.commitTransaction("collapse/expand");
PRO                 }
PRO               } 
PRO             },
PRO             $(go.Shape, "TriangleUp",
PRO               { name: "SHAPE", width: 6, height: 4 })),
PRO            //the list of Panels, each showing an attribute
PRO            $(go.Panel, "Vertical",
PRO              {
PRO              name: "LIST",
PRO              row: 1,
PRO              padding: 3,
PRO              alignment: go.Spot.TopLeft,
PRO              defaultAlignment: go.Spot.Left,
PRO              stretch: go.GraphObject.Horizontal,
PRO              itemTemplate: itemTempl
PRO           },
PRO             new go.Binding("itemArray", "items"))
PRO         )  // end Table Panel
PRO       );  // end Node
PRO 
PRO     // define the Link template, representing a relationship
PRO     myDiagram.linkTemplate =
PRO       $(go.Link,  // the whole link panel
PRO         {
PRO           selectionAdorned: true,
PRO           layerName: "Foreground",
PRO           reshapable: true,
PRO           routing: go.Link.AvoidsNodes,
PRO           corner: 5,
PRO           curve: go.Link.JumpOver
PRO         },
PRO         $(go.Shape,  // the link shape
PRO           { stroke: "#303B45", strokeWidth: 2.5 }),
PRO         $(go.TextBlock,  // the "from" label
PRO           {
PRO             textAlign: "center",
PRO             font: "bold 14px sans-serif",
PRO             stroke: "#1967B3",
PRO             segmentIndex: 0,
PRO             segmentOffset: new go.Point(NaN, NaN),
PRO             segmentOrientation: go.Link.OrientUpright
PRO           },
PRO           new go.Binding("text", "text")),
PRO         $(go.TextBlock,  // the "to" label
PRO           {
PRO             textAlign: "center",
PRO             font: "bold 14px sans-serif",
PRO             stroke: "#1967B3",
PRO             segmentIndex: -1,
PRO             segmentOffset: new go.Point(NaN, NaN),
PRO             segmentOrientation: go.Link.OrientUpright
PRO           },
PRO           new go.Binding("text", "toText"))
PRO       );
PRO 
PRO     // create the model for the E-R diagram
PRO     var nodeDataArray = [

SELECT 
       '{ key: '
       || '"'
       || table_name
       || '"'
       || ' },'
FROM
       (
              SELECT DISTINCT
                     owner
                   ,table_name
              FROM
                     dba_constraints
              WHERE
                     constraint_type = 'R'
                 AND owner           ='&owner'
              UNION
              SELECT
                     owner
                   ,table_name
              FROM
                     dba_Tables
              WHERE
                     (
                            owner,table_name
                     )
                     IN
                     (
                            SELECT
                                   owner
                                 ,table_name
                            FROM
                                   dba_constraints
                            WHERE
                                   (
                                          owner,constraint_name
                                   )
                                   IN
                                   (
                                          SELECT
                                                 owner
                                               ,r_constraint_name
                                          FROM
                                                 dba_constraints
                                          WHERE
                                                 constraint_type = 'R'
                                             AND owner           ='&owner'
                                   )
                     )
       );
       
PRO     ];
PRO     var linkDataArray = [

select '{ from: "' || parent_table_name || '"' || ', to: "' || table_name || '"' || ', text: "0..N", toText: "1" },'
  from (
  SELECT DISTINCT
                       a.table_name AS table_name
                     , b.table_name AS parent_table_name
                FROM
                       dba_constraints a
                LEFT OUTER JOIN dba_constraints b
                ON
                       a.r_constraint_name = b.constraint_name
                   AND a.owner             = b.owner
                WHERE
                       a.owner = '&owner' ) where parent_table_name is not null;

PRO     ];
PRO     myDiagram.model = new go.GraphLinksModel(nodeDataArray, linkDataArray);
PRO   }
PRO </script>
PRO </head>
PRO <body onload="init()">
PRO <div id="sample">
PRO   <div id="myDiagram" style="background-color: white; border: solid 1px black; width: 100%; height: 850px"></div>
PRO </div>
PRO </body>
PRO </html>
PRO 
SPO OFF;
SET HEA ON LIN 80 NEWP 1 PAGES 14 FEED ON ECHO OFF VER ON LONG 80 LONGC 80 WRA ON TRIMS OFF TRIM OFF TI OFF TIMI OFF ARRAY 15 NUM 10 NUMF "" SQLBL OFF BLO ON RECSEP WR;

@sqlplus_settings.bak

host start chrome C:\Users\U267399\Desktop\Tools\scripts\logs\er.html