import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientsPage extends StatefulWidget {
  final String role; // 'trainer' or 'nutritionist'
  
  const ClientsPage({super.key, required this.role});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  int _selectedFilter = 0; // 0: All, 1: Active, 2: Needs attention, 3: New, 4: Archived
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  final List<String> _filters = ['All', 'Active', 'Needs attention', 'New', 'Archived'];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual connection query
      // For now, return empty list
      // Query should be: SELECT * FROM connections WHERE trainer_id = current_user_id AND status = 'accepted'
      
      if (mounted) {
        setState(() {
          _clients = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [CLIENTS] Error loading clients: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          'My Clients',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = index);
                      _loadClients();
                    },
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF1F2937)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Clients list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No clients yet',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start connecting with clients to see them here',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClients,
                        color: const Color(0xFF6366F1),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _clients.length,
                          itemBuilder: (context, index) {
                            return _buildClientCard(_clients[index], isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to client detail page
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                color: const Color(0xFF6366F1),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client['name'] ?? 'Client',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last active: Today',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 14, color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '7',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '85%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

