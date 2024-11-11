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
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Wrap(
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
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: FruchtermanReingoldAlgorithm(),
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
        ],
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
  Set<String> allNodes = <String>{}; //Store all nodes
  Map<String, int> nodeDistances = {}; //from_to format for key

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
    // Remove existing nodes
    for (var n in graph.nodes) {
      graph.removeNode(n);
    }
    if (kDebugMode) {
      print("REMOVED EXISTING NODES");
    }
    // Add nodes from allNode
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
    if (kDebugMode) {
      print("ADDED NEW NODES");
    }
    // Setup the connections
    for (var c in connections) {
      graph.addEdge(
          graph.getNodeUsingId(c.nodeOne), graph.getNodeUsingId(c.nodeTwo));
      graph.addEdge(
          graph.getNodeUsingId(c.nodeTwo), graph.getNodeUsingId(c.nodeOne));
    }
  }

  @override
  void initState() {
    super.initState();
    graph.addNode(Node.Id("Dummy"));
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
