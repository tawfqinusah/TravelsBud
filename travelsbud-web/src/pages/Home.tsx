import React from 'react';
import { Container, Typography, Button, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Home = () => {
  const navigate = useNavigate();

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 4,
        }}
      >
        <Typography variant="h2" component="h1" gutterBottom>
          TravelsBud
        </Typography>
        
        <Typography variant="h5" align="center" color="textSecondary" paragraph>
          Your ultimate travel companion. Connect with fellow travelers, share experiences, and make your journey unforgettable.
        </Typography>

        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', justifyContent: 'center' }}>
          <Button
            variant="contained"
            color="primary"
            size="large"
            onClick={() => window.location.href = 'https://apps.apple.com/your-app-link'}
          >
            Download App
          </Button>
          <Button
            variant="outlined"
            color="primary"
            size="large"
            onClick={() => navigate('/login')}
          >
            Web Login
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            size="large"
            onClick={() => navigate('/signup')}
          >
            Create Account
          </Button>
        </Box>
      </Box>
    </Container>
  );
};

export default Home; 