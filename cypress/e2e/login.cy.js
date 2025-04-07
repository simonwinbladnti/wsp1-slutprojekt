describe('Login Flow', () => {
    beforeEach(() => {
      cy.visit('/login');
    });
  
    it('should show login page', () => {
      cy.contains('Login');
    });
  
    it('fails with wrong credentials', () => {
      cy.get('input[name="username"]').type('wronguser');
      cy.get('input[name="password"]').type('wrongpass');
      cy.get('form').submit();
  
      cy.contains('Invalid username or password');
    });
  
    it('logs in successfully with correct credentials', () => {
      cy.get('input[name="username"]').type('admin');
      cy.get('input[name="password"]').type('admin'); 
      cy.get('form').submit();
  
      cy.url().should('include', '/teams');
      cy.contains('Teams');
    });
  });
  