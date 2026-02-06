import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/apiService/details.api.dart';
import 'package:cnlas/util/authService.util.dart';
import 'package:flutter/material.dart';

class InputDetailsScreen extends StatefulWidget {
  const InputDetailsScreen({super.key, required this.email, required this.name});

  final String email;
  final String name;

  @override
  State<InputDetailsScreen> createState() => _InputDetailsScreenState();
}

class _InputDetailsScreenState extends State<InputDetailsScreen> {
  final authService = AuthAPI();
  final detailsService = DetailsApi();
  final jwt = AuthService();
  
  List<String> buildings = [];
  List<String> departments = [];
  
  TextEditingController departmentController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController officeBuildingController = TextEditingController();
  TextEditingController officeNumberController = TextEditingController();
  
  String? selectedBuilding;
  String? selectedDepartment;
  
  bool isLoadingBuildings = true;
  bool isLoadingDepartments = true;
  bool isSubmitting = false;
  String? errorMessage;

  final GlobalKey<FormState> _inputDetailsKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
    nameController.text = widget.name;
    _loadDropdownData();
  }

  @override
  void dispose() {
    departmentController.dispose();
    emailController.dispose();
    nameController.dispose();
    officeBuildingController.dispose();
    officeNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    print('🔄 Starting to load dropdown data...');
    
    setState(() {
      isLoadingBuildings = true;
      isLoadingDepartments = true;
      errorMessage = null;
    });

    try {
      // Load locations
      print('📍 Loading locations...');
      final locationsFuture = detailsService.getLocationNames();
      
      // Load departments
      print('🏫 Loading departments...');
      final departmentsFuture = detailsService.getDepartmentNames();

      // Wait for both
      final results = await Future.wait([
        locationsFuture,
        departmentsFuture,
      ]);

      print('✅ Locations loaded: ${results[0].length} items');
      print('📋 Locations: ${results[0]}');
      
      print('✅ Departments loaded: ${results[1].length} items');
      print('📋 Departments: ${results[1]}');

      if (!mounted) return;

      setState(() {
        buildings = results[0];
        departments = results[1];
        isLoadingBuildings = false;
        isLoadingDepartments = false;
      });

      print('✅ Dropdown data loaded successfully!');
      
    } catch (e) {
      print('❌ Error loading dropdown data: $e');
      
      if (!mounted) return;
      
      setState(() {
        isLoadingBuildings = false;
        isLoadingDepartments = false;
        errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading data: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadDropdownData,
          ),
        ),
      );
    }
  }

  Future<void> _handleInputDetails(
    String email,
    String department,
    String officeBuilding,
    String officeNumber,
  ) async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final statusCode = await detailsService.inputDetails(
        email,
        department,
        officeBuilding,
        officeNumber,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Detail upload unsuccessful"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDropdownData,
              tooltip: 'Retry loading data',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your details",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    "Provide your information to complete your profile.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  
                  // Show error message if data failed to load
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Failed to load data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadDropdownData,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
            
                  Form(
                    key: _inputDetailsKey,
                    child: Column(
                      children: [  
                        TextFormField(
                          controller: emailController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: nameController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Department Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Department',
                            hintText: isLoadingDepartments 
                              ? 'Loading departments...' 
                              : departments.isEmpty 
                                ? 'No departments available'
                                : 'Select Department',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: isLoadingDepartments
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          ),
                          value: selectedDepartment,
                          items: departments.isEmpty
                            ? null
                            : departments.map((String department) {
                                return DropdownMenuItem<String>(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                          onChanged: (isLoadingDepartments || departments.isEmpty)
                            ? null 
                            : (String? newValue) {
                                setState(() {
                                  selectedDepartment = newValue;
                                });
                              },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a department';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Office Building Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Office Building",
                            hintText: isLoadingBuildings 
                              ? 'Loading buildings...' 
                              : buildings.isEmpty
                                ? 'No buildings available'
                                : 'Select Office Building',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: isLoadingBuildings
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          ),
                          value: selectedBuilding,
                          items: buildings.isEmpty
                            ? null
                            : buildings.map((String building) {
                                return DropdownMenuItem<String>(
                                  value: building,
                                  child: Text(building),
                                );
                              }).toList(),
                          onChanged: (isLoadingBuildings || buildings.isEmpty)
                            ? null 
                            : (String? newValue) {
                                setState(() {
                                  selectedBuilding = newValue;
                                });
                              },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an office building';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: officeNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Office Number',
                            hintText: "e.g. F104",
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your office number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
            
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isLoadingBuildings || 
                                       isLoadingDepartments || 
                                       isSubmitting ||
                                       buildings.isEmpty ||
                                       departments.isEmpty) 
                              ? null 
                              : () async {
                                  if (_inputDetailsKey.currentState!.validate()) {
                                    await _handleInputDetails(
                                      emailController.text,
                                      selectedDepartment!,
                                      selectedBuilding!,
                                      officeNumberController.text,
                                    );
                                  }
                                },
                            child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text("Proceed"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}