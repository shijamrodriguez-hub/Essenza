import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController producerCodeController = TextEditingController(); // Controlador para el código de enlace

  String selectedRole = 'productor'; // 'productor' o 'consulta'

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    producerCodeController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Llamado al AuthService enviando el código de enlace si es usuario de consulta
    final success = await AuthService.register(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
      linkedProducerCode: selectedRole == 'consulta' ? producerCodeController.text : null,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '¡Cuenta creada! 🌱',
              style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold),
            ),
            content: Text(
              selectedRole == 'productor'
                  ? 'Tu cuenta como Productor ha sido creada correctamente.'
                  : 'Tu cuenta como Usuario de consulta ha sido vinculada correctamente.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Regresa al Login o pantalla anterior
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este correo ya está registrado.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 480 : double.infinity,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Regístrate para gestionar o monitorear tus cultivos de forma local.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Selector de Rol
                    const Text(
                      'Selecciona tu rol:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Productor')),
                            selected: selectedRole == 'productor',
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: selectedRole == 'productor' ? Colors.white : const Color(0xFF1B4332),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                selectedRole = 'productor';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Consulta')),
                            selected: selectedRole == 'consulta',
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: selectedRole == 'consulta' ? Colors.white : const Color(0xFF1B4332),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                selectedRole = 'consulta';
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nombre Completo
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2E7D32)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                    ),

                    const SizedBox(height: 16),

                    // Correo Electrónico
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || !value.contains('@') ? 'Ingresa un correo válido' : null,
                    ),

                    const SizedBox(height: 16),

                    // Contraseña
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2E7D32)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),

                    const SizedBox(height: 16),

                    // Confirmar Contraseña
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2E7D32)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Confirma tu contraseña' : null,
                    ),

                    // CAMPO CONDICIONAL: Solo aparece si el rol es 'consulta' para ingresar el código del productor
                    if (selectedRole == 'consulta') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: producerCodeController,
                        decoration: InputDecoration(
                          labelText: 'Código de Finca del Productor',
                          hintText: 'Ej. ESC-123456',
                          prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFFFB8C00)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (selectedRole == 'consulta' && (value == null || value.isEmpty)) {
                            return 'Ingresa el código del productor para enlazar tu cuenta';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Botón de Registro
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : registerUser,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Registrarse',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}