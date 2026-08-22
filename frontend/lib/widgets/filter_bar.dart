import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class FilterBar extends StatefulWidget {
  final Function(String?, bool?, int?) onFilterChanged;

  const FilterBar({super.key, required this.onFilterChanged});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  String? _selectedHostel;
  String? _selectedAc;
  String? _selectedSeater;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterDropdown(
              label: 'Hostel',
              value: _selectedHostel,
              items: ['All', ...AppConstants.allHostels],
              onChanged: (value) {
                setState(() => _selectedHostel = value == 'All' ? null : value);
                _applyFilters();
              },
            ),
            const SizedBox(width: 12),

            _buildFilterDropdown(
              label: 'AC',
              value: _selectedAc,
              items: ['All', 'AC', 'Non-AC'],
              onChanged: (value) {
                setState(() => _selectedAc = value == 'All' ? null : value);
                _applyFilters();
              },
            ),
            const SizedBox(width: 12),

            _buildFilterDropdown(
              label: 'Seater',
              value: _selectedSeater,
              items: ['All', '2', '3', '4', '5'],
              onChanged: (value) {
                setState(() => _selectedSeater = value == 'All' ? null : value);
                _applyFilters();
              },
            ),
            const SizedBox(width: 12),

            // Clear filters button
            if (_selectedHostel != null || _selectedAc != null || _selectedSeater != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedHostel = null;
                    _selectedAc = null;
                    _selectedSeater = null;
                  });
                  _applyFilters();
                },
                child: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value ?? items.first,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        style: TextStyle(color: Colors.black, fontSize: 14),
        isDense: true,
      ),
    );
  }

  void _applyFilters() {
    widget.onFilterChanged(
      _selectedHostel,
      _selectedAc == 'AC' ? true : (_selectedAc == 'Non-AC' ? false : null),
      _selectedSeater != null ? int.tryParse(_selectedSeater!) : null,
    );
  }
}