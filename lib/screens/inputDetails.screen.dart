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
  // Changed to empty lists that will be populated from API
  List<String> buildings = [];

  TextEditingController departmentController = TextEditingController();
  List<String> departments = [];
  final detailsService = DetailsApi();
  TextEditingController emailController = TextEditingController();
   // Loading states
  bool isLoadingBuildings = true;

  bool isLoadingDepartments = true;
  final jwt = AuthService();
  //controllers
  TextEditingController nameController = TextEditingController();

  TextEditingController officeBuildingController = TextEditingController();
  TextEditingController officeNumberController = TextEditingController();
  String? selectedBuilding;
  String? selectedDepartment;

  final GlobalKey<FormState> _inputDetailsKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  // Fetch data from API
  Future<void> _loadDropdownData() async {
    try {
      // Fetch both locations and departments
      final locationsResponse = await detailsService.getLocationNames();
      final departmentsResponse = await detailsService.getDepartmentNames();

      if (!mounted) return;

      setState(() {
        buildings = locationsResponse;
        departments = departmentsResponse;
        isLoadingBuildings = false;
        isLoadingDepartments = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoadingBuildings = false;
        isLoadingDepartments = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    }
  }

  Future<void> _handleInputDetails(String email, String department, String officeBuilding, String officeNumber) async {
    try {
      final user = await detailsService.inputDetails(email, department, officeBuilding, officeNumber);

      if (!mounted) return;

      if (user == 201) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // maybe navigate somewhere else
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Detail Upload unsuccessful")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    emailController.text = widget.email;
    nameController.text = widget.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up", style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),),
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
                    
                  // Subtitle
                  Text(
                    "Provide your information to complete your profile.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 32),
              
                  Form(
                    key: _inputDetailsKey,
                    child: Column(
                      children: [  
                        // Input fields
                        TextFormField(
                          controller: emailController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          showCursor: false,
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
                          showCursor: false,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                       // Department Dropdown with loading state
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Department',
                            hintText: isLoadingDepartments ? 'Loading...' : 'Select Department',
                            floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
                          initialValue: selectedDepartment,
                          items: isLoadingDepartments 
                            ? [] 
                            : departments.map((String department) {
                                return DropdownMenuItem<String>(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                          onChanged: isLoadingDepartments 
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

                        // Office Building Dropdown with loading state
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Office Building",
                            hintText: isLoadingBuildings ? 'Loading...' : 'Select Office Building',
                            floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
                          initialValue: selectedBuilding,
                          items: isLoadingBuildings 
                            ? [] 
                            : buildings.map((String building) {
                                return DropdownMenuItem<String>(
                                  value: building,
                                  child: Text(building),
                                );
                              }).toList(),
                          onChanged: isLoadingBuildings 
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
                            hintText: "Room number",
                            floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your office number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 32),
              
                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isLoadingBuildings || isLoadingDepartments) 
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
                            child: (isLoadingBuildings || isLoadingDepartments)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Proceed"),
                          ),
                        ),
                      ],
                    )
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