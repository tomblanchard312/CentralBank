import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { MonetaryOps } from '../pages/MonetaryOps';
import { BrowserRouter } from 'react-router-dom';

const renderWithProviders = (ui: React.ReactElement) => {
  return render(
    <BrowserRouter>
      {ui}
    </BrowserRouter>
  );
};

describe('ECB Safety Enforcement', () => {
  it('requires confirmation and justification for destructive actions', () => {
    renderWithProviders(<MonetaryOps />);

    fireEvent.click(screen.getByRole('button', { name: /suspend minting/i }));

    const dialog = screen.getByRole('dialog', { name: /confirm global suspension/i });
    const confirmButton = screen.getByRole('button', { name: /^confirm$/i });

    expect(dialog).toBeInTheDocument();
    expect(confirmButton).toBeDisabled();

    fireEvent.change(screen.getByPlaceholderText(/required/i), {
      target: { value: 'Emergency suspension' },
    });

    expect(confirmButton).toBeEnabled();
  });

  it('does not submit an empty justification and allows the operator to cancel', () => {
    renderWithProviders(<MonetaryOps />);

    fireEvent.click(screen.getByRole('button', { name: /suspend minting/i }));

    const dialog = screen.getByRole('dialog', { name: /confirm global suspension/i });
    const confirmButton = screen.getByRole('button', { name: /^confirm$/i });

    fireEvent.click(confirmButton);
    expect(dialog).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
