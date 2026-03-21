import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fin_aimt/screens/upi/payment_screen.dart';

class ContactSyncView extends StatefulWidget {
  const ContactSyncView({super.key});

  @override
  State<ContactSyncView> createState() => _ContactSyncViewState();
}

class _ContactSyncViewState extends State<ContactSyncView> {
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // These would be fetched from your backend (registered users' phone numbers)
  final Set<String> _registeredNumbers = {
    '+919876543210',
    '+918765432109',
    '+917654321098',
  };

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status == PermissionStatus.granted) {
      final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filtered = _contacts;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isRegistered(Contact c) {
    if (c.phones.isEmpty) return false;
    final phones = c.phones.map((p) =>
        p.number.replaceAll(RegExp(r'\s+|-'), ''));
    return phones.any((p) => _registeredNumbers.contains(p));
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = _contacts
          .where((c) =>
              (c.displayName ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Pay a Contact', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search name or number',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? const Center(
                  child: Text('No contacts found',
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final contact = _filtered[index];
                    final registered = _isRegistered(contact);
                    final displayName = contact.displayName ?? 'Unknown';
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: registered
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : '',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: registered
                          ? ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    receiverId: contact.id ?? '',
                                    receiverName: displayName,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: const StadiumBorder()),
                              child: const Text('Pay', style: TextStyle(color: Colors.white)),
                            )
                          : const Text('Not on app',
                              style: TextStyle(color: Colors.white38, fontSize: 12)),
                    );
                  },
                ),
    );
  }
}
