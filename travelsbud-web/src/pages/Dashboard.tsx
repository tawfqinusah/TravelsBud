import React from 'react';
import { Container, Typography, Button, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';

const Dashboard = () => {
  const navigate = useNavigate();

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <Container maxWidth="md">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 4,
        }}
      >
        <Typography variant="h3" component="h1">
          Welcome to TravelsBud
        </Typography>

        <Typography variant="h6" color="textSecondary">
          Start exploring and connecting with fellow travelers!
        </Typography>

        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={() => navigate('/profile')}
          >
            View Profile
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            onClick={handleSignOut}
          >
            Sign Out
          </Button>
        </Box>
      </Box>
    </Container>
  );
};

export default Dashboard; 