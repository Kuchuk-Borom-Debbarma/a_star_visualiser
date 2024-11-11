import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: TreeViewPage(),
      );
}

class TreeViewPage extends StatefulWidget {
  const TreeViewPage({super.key});

  @override
  TreeViewPageState createState() => TreeViewPageState();
}

class TreeViewPageState extends State<TreeViewPage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Responsive(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tree View'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add Connection'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _fromController,
                                decoration: const InputDecoration(
                                  labelText: 'From',
                                ),
                              ),
                              TextField(
                                controller: _toController,
                                decoration: const InputDecoration(
                                  labelText: 'To',
                                ),
                              ),
                              TextField(
                                controller: _distanceController,
                                decoration: const InputDecoration(
                                  labelText: 'Distance',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                String from = _fromController.text;
                                String to = _toController.text;
                                int distance =
                                    int.tryParse(_distanceController.text) ?? 0;

                                if (_addConnection(from, to, distance)) {
                                  _generateGraph();
                                }
                                setState(() {});

                                _fromController.clear();
                                _toController.clear();
                                _distanceController.clear();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Connect'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("Add Connection"),
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: FruchtermanReingoldAlgorithm(
                        renderer: CustomEdgeRenderer(connections)),
                    paint: Paint()
                      ..color = Colors.green
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      var a = node.key?.value as String;
                      return rectangleWidget(a);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rectangleWidget(String a) {
    return InkWell(
      onTap: () {
        if (kDebugMode) {
          print('clicked');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.lightBlueAccent.withOpacity(0.5),
        ),
        child: Text(a),
      ),
    );
  }

  final Graph graph = Graph();
  Set<String> allNodes = <String>{};
  List<Connection> connections = [];

  bool _addConnection(String from, String to, int distance) {
    var newCon = Connection(nodeOne: from, nodeTwo: to, distance: distance);
    if (connections.any((c) => c.same(newCon))) {
      if (kDebugMode) {
        print("Connection already exists: $newCon");
      }
      return false;
    }
    connections.add(newCon);
    return true;
  }

  void _generateGraph() {
    for (var n in graph.nodes) {
      graph.removeNode(n);
    }
    for (var c in connections) {
      if (!graph.contains(node: Node.Id(c.nodeOne))) {
        final node = Node.Id(c.nodeOne);
        graph.addNode(node);
        node.position =
            Offset(Random().nextDouble() * 400, Random().nextDouble() * 400);
      }
      if (!graph.contains(node: Node.Id(c.nodeTwo))) {
        final node = Node.Id(c.nodeTwo);
        graph.addNode(node);
        node.position =
            Offset(Random().nextDouble() * 400, Random().nextDouble() * 400);
      }
    }
    for (var c in connections) {
      graph.addEdge(
        graph.getNodeUsingId(c.nodeOne),
        graph.getNodeUsingId(c.nodeTwo),
      );
      graph.addEdge(
        graph.getNodeUsingId(c.nodeTwo),
        graph.getNodeUsingId(c.nodeOne),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    graph.addNode(Node.Id("Dummy"));
  }
}

class CustomEdgeRenderer extends EdgeRenderer {
  final List<Connection> connections;

  CustomEdgeRenderer(this.connections);

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    for (var edge in graph.edges) {
      final p1 = edge.source.position;
      final p2 = edge.destination.position;
      final midpoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      // Find the connection to get the distance
      final connection = connections.firstWhere(
        (c) =>
            (c.nodeOne == edge.source.key?.value &&
                c.nodeTwo == edge.destination.key?.value) ||
            (c.nodeTwo == edge.source.key?.value &&
                c.nodeOne == edge.destination.key?.value),
        orElse: () => Connection(nodeOne: '', nodeTwo: '', distance: 0),
      );

      // Draw the edge line
      canvas.drawLine(p1, p2, paint);

      // Draw the distance label
      final textPainter = TextPainter(
        text: TextSpan(
          text: connection.distance.toString(),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(midpoint.dx - textPainter.width / 2,
            midpoint.dy - textPainter.height / 2),
      );
    }
  }
}

class Connection {
  String nodeOne;
  String nodeTwo;
  int distance;

  Connection({
    required this.nodeOne,
    required this.nodeTwo,
    required this.distance,
  });

  bool same(Connection other) {
    return (nodeOne == other.nodeOne && nodeTwo == other.nodeTwo) ||
        (nodeOne == other.nodeTwo && nodeTwo == other.nodeOne);
  }

  @override
  String toString() {
    return 'Connection{nodeOne: $nodeOne, nodeTwo: $nodeTwo, distance: $distance}';
  }
}

class Responsive extends StatelessWidget {
  final Widget child;

  const Responsive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SingleChildScrollView(
            child: child,
          );
        } else {
          return child;
        }
      },
    );
  }
}
