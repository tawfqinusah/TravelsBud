import React from 'react';
import { Container, Typography, Box, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Profile = () => {
  const navigate = useNavigate();

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
        <Typography variant="h3" component="h1" gutterBottom>
          About TravelsBud
        </Typography>

        <Typography variant="body1" paragraph>
          TravelsBud is your perfect companion for exploring the world. Connect with fellow travelers,
          share your experiences, and discover new destinations together.
        </Typography>

        <Typography variant="body1" paragraph>
          Features:
          • Create your travel profile
          • Share your journey
          • Connect with travelers
          • Plan trips together
          • Share photos and stories
        </Typography>

        <Button
          variant="contained"
          color="primary"
          size="large"
          onClick={() => navigate('/')}
        >
          Back to Home
        </Button>
      </Box>
    </Container>
  );
};

export default Profile; 