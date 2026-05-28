<?php
// PHP form processing
$message_sent = false;
$error_message = '';

if (isset($_POST['submit'])) {
    $name = trim($_POST['name']);
    $email = trim($_POST['email']);
    $subject = trim($_POST['subject']);
    $message = trim($_POST['message']);
    
    // Basic validation
    if (empty($name) || empty($email) || empty($subject) || empty($message)) {
        $error_message = 'Please fill in all required fields.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error_message = 'Please enter a valid email address.';
    } else {
        // Prepare email
        $to = 'support@shaffex.com';
        $email_subject = 'Contact Form: ' . $subject;
        $email_body = "Name: $name\n";
        $email_body .= "Email: $email\n";
        $email_body .= "App: Boarding Pass Scanner\n\n";
        $email_body .= "Subject: $subject\n\n";
        $email_body .= "Message:\n$message\n";
        
        $headers = "From: $email\r\n";
        $headers .= "Reply-To: $email\r\n";
        $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
        
        // Send email
        if (mail($to, $email_subject, $email_body, $headers)) {
            $message_sent = true;
        } else {
            $error_message = 'Sorry, there was an error sending your message. Please try again.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="theme-color" content="#f2f2f7" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="default">
    <meta name="apple-mobile-web-app-title" content="Contact Us">
    <title>Contact Us - Shaffex App Support</title>
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        html {
            background-color: #f2f2f7; /* iOS light mode background */
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f2f2f7; /* iOS light mode background */
            min-height: 100vh;
            padding: 20px;
            color: #333;
            min-height: 100dvh;
            overscroll-behavior-y: contain;
            -webkit-overflow-scrolling: touch;
        }
        
        .container {
            max-width: 400px;
            margin: 0 auto;
            background: #ffffff; /* iOS grouped table view background in light mode */
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
            animation: slideUp 0.6s ease-out;
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .header {
            background: #007aff; /* iOS blue accent color */
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .header p {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .form-container {
            padding: 30px 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #2d3748;
            font-size: 14px;
        }
        
        input[type="text"],
        input[type="email"],
        textarea {
            width: 100%;
            padding: 15px;
            border: 1px solid #c6c6c8; /* iOS light mode separator */
            border-radius: 10px; /* iOS standard corner radius */
            font-size: 16px;
            transition: all 0.3s ease;
            font-family: inherit;
            -webkit-appearance: none;
            appearance: none;
            background: #ffffff; /* iOS input background */
        }
        
        input[type="text"]:focus,
        input[type="email"]:focus,
        textarea:focus {
            outline: none;
            border-color: #007aff; /* iOS blue accent color */
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
        }
        
        textarea {
            resize: vertical;
            min-height: 120px;
        }
        
        .submit-btn {
            width: 100%;
            background: #007aff; /* iOS blue accent color */
            color: white;
            border: none;
            padding: 16px;
            border-radius: 10px; /* iOS standard corner radius */
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            -webkit-appearance: none;
            appearance: none;
        }
        
        .submit-btn:hover {
            background: #0056d3; /* Darker iOS blue on hover */
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(0, 122, 255, 0.3);
        }
        
        .submit-btn:active {
            transform: translateY(0);
        }
        
        .success-message {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 20px;
            border-left: 4px solid #28a745;
            animation: fadeIn 0.5s ease;
        }
        
        .error-message {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 20px;
            border-left: 4px solid #dc3545;
            animation: fadeIn 0.5s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            color: #718096;
            font-size: 14px;
        }
        
        /* iOS-specific styling */
        @supports (-webkit-touch-callout: none) {
            input[type="text"],
            input[type="email"],
            textarea {
                font-size: 16px; /* Prevents zoom on iOS */
            }
        }
        
        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            html {
                background-color: #000000; /* iOS dark mode background */
            }
            body {
                background-color: #000000; /* iOS dark mode background */
                color: #ffffff;
                min-height: 100dvh;
                overscroll-behavior-y: contain;
                -webkit-overflow-scrolling: touch;
            }
            
            .container {
                background: #1c1c1e; /* iOS dark mode secondary background */
                color: #ffffff;
            }
            
            input[type="text"],
            input[type="email"],
            textarea {
                background: #1c1c1e; /* iOS dark mode secondary background */
                border-color: #38383a; /* iOS dark mode separator */
                color: #ffffff;
            }
            
            label {
                color: #ffffff;
            }
        }
        
        /* Responsive adjustments */
        @media (max-width: 480px) {
            body {
                padding: 10px;
            }
            
            .container {
                border-radius: 15px;
            }
            
            .header {
                padding: 25px 15px;
            }
            
            .form-container {
                padding: 25px 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Contact Support</h1>
            <p>We're here to help with your app</p>
        </div>
        
        <div class="form-container">
            <?php if ($message_sent): ?>
                <div class="success-message">
                    <strong>Thank you!</strong> Your message has been sent successfully. Our support team will get back to you soon.
                </div>
            <?php endif; ?>
            
            <?php if (!empty($error_message)): ?>
                <div class="error-message">
                    <strong>Error:</strong> <?php echo htmlspecialchars($error_message); ?>
                </div>
            <?php endif; ?>
            
            <?php if (!$message_sent): ?>
                <form method="POST" action="">
                    <div class="form-group">
                        <label for="name">Full Name *</label>
                        <input type="text" id="name" name="name" required 
                               value="<?php echo isset($_POST['name']) ? htmlspecialchars($_POST['name']) : ''; ?>"
                               placeholder="Your full name">
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email Address *</label>
                        <input type="email" id="email" name="email" required 
                               value="<?php echo isset($_POST['email']) ? htmlspecialchars($_POST['email']) : ''; ?>"
                               placeholder="your.email@example.com">
                    </div>
                    
                    <div class="form-group">
                        <label for="subject">Subject *</label>
                        <input type="text" id="subject" name="subject" required 
                               value="<?php echo isset($_POST['subject']) ? htmlspecialchars($_POST['subject']) : ''; ?>"
                               placeholder="Brief description of your issue">
                    </div>
                    
                    <div class="form-group">
                        <label for="message">Message *</label>
                        <textarea id="message" name="message" required 
                                  placeholder="Please describe your issue or question in detail..."><?php echo isset($_POST['message']) ? htmlspecialchars($_POST['message']) : ''; ?></textarea>
                    </div>
                    
                    <button type="submit" name="submit" class="submit-btn">
                        Send Message
                    </button>
                </form>
            <?php else: ?>
                <div style="text-align: center; padding: 20px 0;">
                    <button onclick="location.reload()" class="submit-btn">
                        Send Another Message
                    </button>
                </div>
            <?php endif; ?>
        </div>
        
        <div class="footer">
            <p>Shaffex App Support Team<br>
            We typically respond within 24 hours</p>
        </div>
    </div>
    
    <script>
        // Smooth form submission
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.querySelector('form');
            if (form) {
                form.addEventListener('submit', function(e) {
                    const submitBtn = document.querySelector('.submit-btn');
                    submitBtn.textContent = 'Sending...';
                    submitBtn.style.opacity = '0.7';
                });
            }
            
            // Auto-focus first input on page load
            const firstInput = document.querySelector('input[type="text"]');
            if (firstInput && !document.querySelector('.success-message')) {
                setTimeout(() => firstInput.focus(), 500);
            }
        });
        
        // Prevent form resubmission on page refresh
        if (window.history.replaceState) {
            window.history.replaceState(null, null, window.location.href);
        }
    </script>
</body>
</html>