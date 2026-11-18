package com.centralbank.clover;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.TextView;
import com.clover.sdk.v3.connector.IPaymentConnector;
import com.clover.sdk.v3.connector.PaymentConnector;

public class MainActivity extends AppCompatActivity {

    private IPaymentConnector paymentConnector;
    private TextView statusText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        statusText = findViewById(R.id.statusText);

        // Initialize Clover Payment Connector
        try {
            paymentConnector = new PaymentConnector(this);

            // Register our custom CBDT tender
            paymentConnector.addTender(new CentralBankTender());

            statusText.setText("Clover connector initialized. CBDT tender registered.");
        } catch (Exception e) {
            statusText.setText("Failed to initialize Clover connector: " + e.getMessage());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (paymentConnector != null) {
            paymentConnector.dispose();
        }
    }
}