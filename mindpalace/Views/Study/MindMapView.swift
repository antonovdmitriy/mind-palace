import SwiftUI

struct MindMapView: View {
    let file: MarkdownFile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: MarkdownSection?

    var onSectionTap: (MarkdownSection) -> Void

    // Build graph from document structure
    private var graphData: ([GraphNode], [GraphEdge]) {
        var nodes: [GraphNode] = []
        var edges: [GraphEdge] = []

        // Root node - document name
        let rootNode = GraphNode(
            id: "root",
            label: file.fileName.replacingOccurrences(of: ".md", with: ""),
            level: 0
        )
        nodes.append(rootNode)

        // Add sections as nodes
        let sections = file.sections.sorted(by: { $0.orderIndex < $1.orderIndex })

        for (index, section) in sections.enumerated() {
            let node = GraphNode(
                id: section.id.uuidString,
                label: section.title,
                level: section.level
            )
            nodes.append(node)

            // Connect to root or parent section
            if section.level == 1 {
                // Top level sections connect to root
                edges.append(GraphEdge(
                    source: "root",
                    target: section.id.uuidString
                ))
            } else {
                // Find parent section (previous section with lower level)
                for i in (0..<index).reversed() {
                    let potentialParent = sections[i]
                    if potentialParent.level < section.level {
                        edges.append(GraphEdge(
                            source: potentialParent.id.uuidString,
                            target: section.id.uuidString
                        ))
                        break
                    }
                }
            }
        }

        return (nodes, edges)
    }

    var body: some View {
        let (nodes, edges) = graphData

        NavigationStack {
            ZStack {
                // Background color based on theme
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()

                if nodes.count > 1 {
                    ForceDirectedGraphView(
                        nodes: nodes,
                        edges: edges,
                        colorScheme: colorScheme,
                        onNodeTap: { nodeId in
                            // Find section by ID and call callback
                            if let section = file.sections.first(where: { $0.id.uuidString == nodeId }) {
                                selectedSection = section
                                onSectionTap(section)
                                dismiss()
                            }
                        }
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No sections to display")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("This document doesn't have any sections yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Mind Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Graph node model
struct GraphNode: Identifiable {
    let id: String
    let label: String
    let level: Int
}

// Graph edge model
struct GraphEdge: Identifiable {
    var id: String { "\(source)-\(target)" }
    let source: String
    let target: String
}

// Force-directed graph view with tree layout
struct ForceDirectedGraphView: View {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
    let colorScheme: ColorScheme
    let onNodeTap: (String) -> Void

    @State private var scale: CGFloat = 0.5
    @State private var offset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero

    // Branch colors - vibrant palette
    private let branchColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal, .yellow
    ]

    // Calculate branch color for a node based on its root parent
    private func getBranchIndex(for nodeId: String) -> Int {
        // Find the root parent (level 1 node)
        var currentId = nodeId
        var parentMap: [String: String] = [:]

        // Build parent map from edges
        for edge in edges {
            parentMap[edge.target] = edge.source
        }

        // Trace back to find level 1 parent
        while let parent = parentMap[currentId], parent != "root" {
            currentId = parent
        }

        // Get index of the level 1 parent
        if let rootChild = nodes.first(where: { $0.id == currentId && $0.level == 1 }) {
            let level1Nodes = nodes.filter { $0.level == 1 }.sorted { $0.id < $1.id }
            return level1Nodes.firstIndex(where: { $0.id == rootChild.id }) ?? 0
        }

        return 0
    }

    // Calculate positions using radial brain-like layout
    private func calculateNodePositions(in size: CGSize) -> [String: CGPoint] {
        var positions: [String: CGPoint] = [:]

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        positions["root"] = center

        // Group nodes by level
        var nodesByLevel: [Int: [GraphNode]] = [:]
        for node in nodes where node.id != "root" {
            nodesByLevel[node.level, default: []].append(node)
        }

        // Position nodes in concentric circles
        for (level, nodesAtLevel) in nodesByLevel.sorted(by: { $0.key < $1.key }) {
            let radius = CGFloat(level) * 250 // Large spacing between levels
            let angleStep = (2 * .pi) / Double(nodesAtLevel.count)

            for (index, node) in nodesAtLevel.enumerated() {
                let angle = angleStep * Double(index) - .pi / 2 // Start from top
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)

                positions[node.id] = CGPoint(x: x, y: y)
            }
        }

        return positions
    }

    var body: some View {
        GeometryReader { geometry in
            let positions = calculateNodePositions(in: geometry.size)

            ZStack {
                // Background
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()

                // Draw edges behind nodes
                ForEach(edges) { edge in
                    if let sourcePos = positions[edge.source],
                       let targetPos = positions[edge.target] {
                        let branchIndex = getBranchIndex(for: edge.target)
                        let branchColor = branchColors[branchIndex % branchColors.count]

                        EdgeLine(
                            from: sourcePos,
                            to: targetPos,
                            color: branchColor
                        )
                    }
                }

                // Draw nodes on top
                ForEach(nodes) { node in
                    if let position = positions[node.id] {
                        let branchIndex = getBranchIndex(for: node.id)
                        let branchColor = branchColors[branchIndex % branchColors.count]

                        NodeView(
                            node: node,
                            position: position,
                            colorScheme: colorScheme,
                            branchColor: node.id == "root" ? nil : branchColor,
                            onTap: {
                                if node.id != "root" {
                                    onNodeTap(node.id)
                                }
                            }
                        )
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.3, min(value, 3.0))
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastDragValue.width + value.translation.width,
                            height: lastDragValue.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastDragValue = offset
                    }
            )
        }
    }
}

// Node view
struct NodeView: View {
    let node: GraphNode
    let position: CGPoint
    let colorScheme: ColorScheme
    let branchColor: Color?
    let onTap: () -> Void

    private var nodeColor: Color {
        if node.id == "root" {
            return colorScheme == .dark ? .blue.opacity(0.8) : .blue
        }

        // Use branch color if available
        if let branchColor = branchColor {
            return colorScheme == .dark ? branchColor.opacity(0.8) : branchColor
        }

        return colorScheme == .dark ? .gray.opacity(0.7) : .gray
    }

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(nodeColor)
                .frame(width: node.id == "root" ? 80 : 50, height: node.id == "root" ? 80 : 50)
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2), lineWidth: 3)
                )
                .shadow(color: nodeColor.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(node.label)
                .font(node.id == "root" ? .title3 : .body)
                .fontWeight(node.id == "root" ? .bold : .semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 140)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .position(position)
        .onTapGesture {
            onTap()
        }
    }
}

// Edge line view
struct EdgeLine: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .opacity(0.6)
    }
}

#Preview {
    let file = MarkdownFile(
        path: "example.md",
        fileName: "example.md",
        content: """
        # Introduction
        Content here

        ## Getting Started
        More content

        ### Installation
        Details

        ## Advanced Topics
        Advanced content
        """
    )

    return MindMapView(file: file) { section in
        print("Tapped: \(section.title)")
    }
}
