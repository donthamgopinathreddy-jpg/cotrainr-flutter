import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  final String planId;
  final String planName;
  final String planPrice;

  const PaymentPage({
    super.key,
    required this.planId,
    required this.planName,
    required this.planPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _discountCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  double _discount = 0.0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _discountCodeController.dispose();
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  double get _originalPrice {
    final priceStr = widget.planPrice.replaceAll('₹', '').trim();
    return double.tryParse(priceStr) ?? 0.0;
  }

  double get _finalPrice {
    return (_originalPrice - _discount).clamp(0.0, double.infinity);
  }

  bool get _canSubmit {
    return _fullNameController.text.trim().isNotEmpty &&
        _addressLine1Controller.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty &&
        _pincodeController.text.trim().length == 6;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Summary Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: widget.planId == 'PREMIUM'
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                              )
                            : widget.planId == 'BASIC'
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF14B8A6), Color(0xFF84CC16)],
                                  )
                                : null,
                        color: widget.planId == 'FREE'
                            ? (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6))
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: widget.planId != 'FREE'
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.planId == 'PREMIUM'
                                  ? Icons.workspace_premium_rounded
                                  : widget.planId == 'BASIC'
                                      ? Icons.star_rounded
                                      : Icons.free_breakfast_rounded,
                              color: widget.planId != 'FREE'
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Plan',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: widget.planId != 'FREE'
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: widget.planId != 'FREE'
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.planPrice,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: widget.planId != 'FREE'
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Discount Code Section
                    _buildSectionHeader('Discount Code', colorScheme, required: false),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _discountCodeController,
                            hint: 'Enter discount code',
                            icon: Icons.local_offer_rounded,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyDiscountCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_discount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Discount applied: ₹${_discount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Billing Address Section
                    _buildSectionHeader('Billing Address', colorScheme),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_rounded,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressLine1Controller,
                      label: 'Address Line 1',
                      hint: 'Street address, building name',
                      icon: Icons.home_rounded,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressLine2Controller,
                      label: 'Address Line 2',
                      hint: 'Apartment, suite, etc. (Optional)',
                      icon: Icons.apartment_rounded,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                            icon: Icons.location_city_rounded,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Enter state',
                            icon: Icons.map_rounded,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter 6-digit pincode',
                      icon: Icons.pin_rounded,
                      keyboardType: TextInputType.number,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.length != 6) {
                          return 'Must be 6 digits';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Price Breakdown
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                widget.planPrice,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (_discount > 0) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '-₹${_discount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '₹${_finalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for sticky button
                  ],
                ),
              ),
            ),
          ),
          // Sticky Payment Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_isProcessing ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: _canSubmit
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.2),
                    foregroundColor: _canSubmit
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : ShaderMask(
                          shaderCallback: (bounds) => _canSubmit
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                                ).createShader(bounds)
                              : const LinearGradient(
                                  colors: [Colors.grey, Colors.grey],
                                ).createShader(bounds),
                          child: const Text(
                            'Proceed to Payment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, {bool required = true}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    String? label,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'Poppins',
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
        prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  void _applyDiscountCode() {
    final code = _discountCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a discount code'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    // TODO: Validate discount code with backend
    double discountAmount = 0.0;
    if (code == 'WELCOME10') {
      discountAmount = _originalPrice * 0.10;
    } else if (code == 'SAVE20') {
      discountAmount = _originalPrice * 0.20;
    } else if (code == 'FIRST50') {
      discountAmount = 50.0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid discount code: $code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _discount = discountAmount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Discount code "$code" applied successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate() && _canSubmit) {
      setState(() {
        _isProcessing = true;
      });

      HapticFeedback.mediumImpact();

      // TODO: Integrate with payment gateway
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Payment Successful!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Your ${widget.planName} subscription has been activated.',
              style: const TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close payment page
                  Navigator.of(context).pop(); // Close subscription page
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
