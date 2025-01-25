from collections import deque
import heapq

# Representasi graf sebagai adjacency list dengan bobot
graph = {
    'A': [('M', 86), ('C', 45), ('K', 65)],
    'M': [('H', 100)],
    'H': [('F', 132)],
    'F': [('B', 210)],
    'C': [('R', 76)],
    'K': [('L', 135)],
    'R': [('T', 85)],
    'T': [('X', 200)],
    'X': [('B', 345)],
    'L': [('S', 148)],
    'S': [('J', 220)],
    'J': [('B', 211)]
}

# BFS (Breadth First Search)
def bfs(graph, start, goal):
    queue = deque([(start, [start], 0)])  # (node saat ini, path sejauh ini, total cost)
    visited = set()
    iterations = 0
    
    print("BFS Proses Antrian dalam Queue:")
    while queue:
        current_node, path, cost = queue.popleft()
        iterations += 1
        
        print(f"Iterasi {iterations}: Node = {current_node}, Path = {path}, Cost = {cost}")
        
        if current_node == goal:
            return path, cost, iterations
        
        if current_node not in visited:
            visited.add(current_node)
            
            for neighbor, weight in graph.get(current_node, []):
                if neighbor not in visited:
                    queue.append((neighbor, path + [neighbor], cost + weight))
    
    return None, float('inf'), iterations

# DFS (Depth First Search)
def dfs(graph, start, goal):
    stack = [(start, [start], 0)]  # (node saat ini, path sejauh ini, total cost)
    visited = set()
    iterations = 0
    
    print("DFS Proses Antrian dalam Stack:")
    while stack:
        current_node, path, cost = stack.pop()
        iterations += 1
        
        print(f"Iterasi {iterations}: Node = {current_node}, Path = {path}, Cost = {cost}")
        
        if current_node == goal:
            return path, cost, iterations
        
        if current_node not in visited:
            visited.add(current_node)
            
            for neighbor, weight in reversed(graph.get(current_node, [])):
                if neighbor not in visited:
                    stack.append((neighbor, path + [neighbor], cost + weight))
    
    return None, float('inf'), iterations

# DLS (Depth Limited Search)
def dls(graph, start, goal, limit):
    stack = [(start, [start], 0)]  # (node saat ini, path sejauh ini, total cost)
    visited = set()
    iterations = 0
    
    print(f"DLS Proses Antrian dalam Stack (Limit = {limit}):")
    while stack:
        current_node, path, cost = stack.pop()
        iterations += 1
        
        print(f"Iterasi {iterations}: Node = {current_node}, Path = {path}, Cost = {cost}")
        
        if current_node == goal:
            return path, cost, iterations
        
        if current_node not in visited and len(path) <= limit:
            visited.add(current_node)
            
            for neighbor, weight in reversed(graph.get(current_node, [])):
                if neighbor not in visited:
                    stack.append((neighbor, path + [neighbor], cost + weight))
    
    return None, float('inf'), iterations

# IDS (Iterative Deepening Search)
def ids(graph, start, goal):
    limit = 0
    iterations_total = 0
    
    while True:
        print(f"\nIDS dengan Limit = {limit}")
        path, cost, iterations = dls(graph, start, goal, limit)
        iterations_total += iterations
        
        if path is not None:
            return path, cost, iterations_total
        
        limit += 1

# UCS (Uniform Cost Search)
def ucs(graph, start, goal):
    priority_queue = [(0, start, [start])]  # (total cost, node saat ini, path sejauh ini)
    visited = set()
    iterations = 0
    
    print("UCS Proses Antrian dalam Priority Queue:")
    while priority_queue:
        cost, current_node, path = heapq.heappop(priority_queue)
        iterations += 1
        
        print(f"Iterasi {iterations}: Node = {current_node}, Path = {path}, Cost = {cost}")
        
        if current_node == goal:
            return path, cost, iterations
        
        if current_node not in visited:
            visited.add(current_node)
            
            for neighbor, weight in graph.get(current_node, []):
                if neighbor not in visited:
                    heapq.heappush(priority_queue, (cost + weight, neighbor, path + [neighbor]))
    
    return None, float('inf'), iterations

# Jalankan semua algoritma
start = 'A'
goal = 'B'

print("=== BFS ===")
bfs_path, bfs_cost, bfs_iterations = bfs(graph, start, goal)
print("\nBFS Path Optimal:", " -> ".join(bfs_path))
print("BFS Path Cost Optimal:", bfs_cost)
print("BFS Iterations:", bfs_iterations)

print("\n=== DFS ===")
dfs_path, dfs_cost, dfs_iterations = dfs(graph, start, goal)
print("\nDFS Path Optimal:", " -> ".join(dfs_path))
print("DFS Path Cost Optimal:", dfs_cost)
print("DFS Iterations:", dfs_iterations)

print("\n=== DLS ===")
dls_path, dls_cost, dls_iterations = dls(graph, start, goal, limit=3)
print("\nDLS Path Optimal:", " -> ".join(dls_path) if dls_path else "No path found within limit")
print("DLS Path Cost Optimal:", dls_cost)
print("DLS Iterations:", dls_iterations)

print("\n=== IDS ===")
ids_path, ids_cost, ids_iterations = ids(graph, start, goal)
print("\nIDS Path Optimal:", " -> ".join(ids_path))
print("IDS Path Cost Optimal:", ids_cost)
print("IDS Iterations:", ids_iterations)

print("\n=== UCS ===")
ucs_path, ucs_cost, ucs_iterations = ucs(graph, start, goal)
print("\nUCS Path Optimal:", " -> ".join(ucs_path))
print("UCS Path Cost Optimal:", ucs_cost)
print("UCS Iterations:", ucs_iterations)