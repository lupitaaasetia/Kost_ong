import 'package:flutter/material.dart';

class ResponsiveSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String) onCategorySelect;
  final VoidCallback? onExplore;
  final VoidCallback? onSchedule;
  final VoidCallback? onFindLocation;

  const ResponsiveSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    required this.onCategorySelect,
    this.onExplore,
    this.onSchedule,
    this.onFindLocation,
  }) : super(key: key);

  @override
  State<ResponsiveSearchBar> createState() => _ResponsiveSearchBarState();
}

class _ResponsiveSearchBarState extends State<ResponsiveSearchBar> {
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Kost Putra',
      'icon': Icons.person,
      'color': Colors.blue,
    },
    {
      'name': 'Kost Putri',
      'icon': Icons.person,
      'color': Colors.pink,
    },
    {
      'name': 'Kost Campur',
      'icon': Icons.people,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            onChanged: widget.onSearch,
            decoration: InputDecoration(
              hintText: 'Cari nama atau alamat kost...',
              prefixIcon: Icon(
                Icons.search,
                color: Color(0xFF4facfe),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // Quick Categories
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cari Berdasarkan Kategori',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: categories
                    .map((category) => Expanded(
                          child: _buildCategoryButton(category),
                        ))
                    .toList()
                    .fold<List<Widget>>([], (list, widget) {
                  if (list.isNotEmpty) list.add(SizedBox(width: 12));
                  list.add(widget);
                  return list;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(Map<String, dynamic> category) {
    return InkWell(
      onTap: () => widget.onCategorySelect(category['name']),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'],
              color: category['color'],
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              category['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
