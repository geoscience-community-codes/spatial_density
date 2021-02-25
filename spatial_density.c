#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <gc.h>
#define CR 13            /* Decimal code of Carriage Return char */
#define LF 10            /* Decimal code of Line Feed char */

#define PI 3.1415926535897932384626433832795029

typedef struct param {
  int spd;
  double west;
  double east;
  double south;
  double north;
  int utm_zone;
  char *datum;
  char *ellps;
  char *proj;
  double grid_spacing;
  char *event_file;
  int samse;
  double smooth_x;
  double smooth_y;
  double rotation;
  char *bandwidth_file;
  /* int plot; */
  char *plotter;
  /* double map_scale;
  double tick_scale;
  char *map_title;*/
  char *output_file;  
} Param;

typedef struct Matrix {
  double h1;
  double h2;
  double h3;
  double h4;
} Matrix;

typedef struct Location {
  double east;
  double north;
} Location;

/*
#############################################
# INPUTS: 
# (1) IN File name of vent locations
# (2) IN/OUT array of vent locations
# OUTPUTS: 
# (1) Number of data lines in the file
############################################# */
Location *load_file(Param *p, int *num_vents, FILE *log) {
  
  FILE *VENTS;
  int maxLineLength = 256;
  char line[256];           /* Line from config file */
  double east;            /* (type=string) Parameter Name  in each line*/
  double north;           /* (type=string) Parameter Value in each line*/
  int i;
  Location *vent;          
  
  /* Open input file of vent locations and create array */
  VENTS = fopen(p->event_file, "r");
  if (VENTS == NULL) {
    fprintf(stderr, "\nERROR : Cannot open %s [%s]!\n", p->event_file, strerror(errno));
    return NULL;
  }
  fprintf(log, "Opening events file %s:\n", p->event_file);
  fflush(log);
  
  *num_vents = 0;
  while (fgets(line, maxLineLength, VENTS) != NULL) {
    if (strlen(line) > 2) (*num_vents)++;
  }
  rewind(VENTS);
  
  vent = (Location *) GC_MALLOC ( (size_t)*num_vents * sizeof(Location));
  if (vent == NULL) {
    fprintf(stderr, "Unable to allocate memory for vent array! Exiting.\n");
    return NULL;
  }
  
  for (i = 0; i < *num_vents; i++) {
    if (fgets(line, maxLineLength, VENTS) == NULL) break;
		
    /*if first character is comment, new line, space, return to next line*/
    if (line[0] == '#' || line[0] == '\n' || line[0] == ' ') continue;
  
    sscanf (line,"%lf %lf", &east, &north); /*split line into easting and northing*/
    /* Convert vent location to km */
    vent[i].east = east/1000.0;
    vent[i].north = north/1000.0;
    fprintf (log, "%lf %lf\n", vent[i].east, vent[i].north); 
  }  
  
  fclose (VENTS);
  fprintf (stderr, "Loaded %d vents from %s\n", *num_vents, p->event_file);
  return vent;
}

double determinant(Matrix *m) {
  return ((m->h1 * m->h4) - (m->h2 * m->h3)); 
}

int sqrtM(Matrix *m, Matrix *sqrtm, double det) {
  
  double trace, t, s, t_inv;
  
  trace = m->h1 + m->h4;
  s = sqrt(det);
  t = sqrt(trace + 2*s);
  t_inv = 1.0/t;
  
  if (!t) {
    return 1;
  }
  else {
    
    sqrtm->h1 = t_inv * (m->h1 + s);
    sqrtm->h2 = t_inv * m->h2;
    sqrtm->h3 = t_inv * m->h3;
    sqrtm->h4 = t_inv * (m->h4 + s);
  }
  return 0; 
}

int inv_matrix(Matrix *sqrtm, Matrix *sqrtmi) {
  
  double det, inv_det;
  det = determinant(sqrtm);
  inv_det = 1.0 / det;
  
  if (!inv_det) {
    return 1;
  }
  else {
    sqrtmi->h1 = inv_det * sqrtm->h4;
    sqrtmi->h2 = inv_det * sqrtm->h2 * -1.0;
    sqrtmi->h3 = inv_det * sqrtm->h3 * -1.0;
    sqrtmi->h4 = inv_det * sqrtm->h1;
  }
  
  return 0;
}

/*##################################################################
# Function gauss($$$$)
# INPUTS: 
# (1) IN X (meters) current grid location
# (2) IN Y (meters) current grid location
# (3) IN reference to array of volcanic vent locations (meters)
# (4) IN number of vent locations
#
# The function uses the following runtime constants:
# (1) $sqrtHi: this is the inverse of the square root 
#     of the (2 x 2)bandwidth matrix
# (2) $Const: this is 2*pi*determinant(H)
# OUTPUTS:
# (1) lambda (i.e. spatial intensity at the current grid location)
####################################################################*/
double gauss(double x1, double y1, Location vent[], int num_vents, double Const, Matrix *ma) {
  
  int i;
  double dx, dy, lambda, dist, edist;
  Matrix dxdy, Mdxdy;
  double sum = 0.0;
  
  //for (i = 0; i < num_vents; i++) { 
  //  fprintf (stderr, "[%d] %lf-%lf %lf-%lf\n", i, x,(vent+i)->east, y,(vent+i)->north);
 // }
  
  for (i = 0; i < num_vents; i++) { 
    //fprintf (stderr, "%d %lf %lf\n", i, (vent+i)->east, (vent+i)->north);
  /* For each event 
     Get distance from event to grid point
   */
      dx = x1 - (vent+i)->east;
      dy = y1 - (vent+i)->north;
     //fprintf (stderr, "dx=%lf = %lf - %lf, dy=%lf = %lf - %lf\n", dx, x1, (vent+i)->east, dy, y1, (vent+i)->north);
      /* note: Tdxdy = dxdy = transpose(dxdy); */      
      dxdy.h1 = dx;
      dxdy.h2 = dy;
      
      Mdxdy.h1 = ma->h1 * dxdy.h1 + ma->h2 * dxdy.h2;
      Mdxdy.h2 = ma->h3 * dxdy.h1 + ma->h4 * dxdy.h2;
     // Mdxdy.h1 = dxdy.h1 * ma->h1 + dxdy.h2 * ma->h3;
     // Mdxdy.h2 = dxdy.h2 * ma->h2 + dxdy.h2 * ma->h4;
      
      dist = (Mdxdy.h1 * Mdxdy.h1) + (Mdxdy.h2 * Mdxdy.h2);
      // dist = (dxdy.h1 * Mdxdy.h1) + (dxdy.h2 * );
      //fprintf(stderr, "[%d]: [%g %g] [%g %g] [%g %g] : distance=%g\n",i, dx, dy, Mdxdy.h1, Mdxdy.h2, dxdy.h1, dxdy.h2, dist);
      
      dist *= -0.5;
      // fprintf (stderr, "%d: %lf m \n", i, dist);
      edist = exp(dist);
      sum += edist;
      //if (sum > 0 && edist > 0) fprintf (stderr, "%d: %e km [%g] %g\n", i, dist, edist, sum);
  }
  lambda = sum/Const;
  return lambda;
}

int main(int argc, char *argv[]) {
  
  FILE *LOG;
  FILE *CONF;
  FILE *KOP;
  FILE *BW;
  FILE *OUT;
  int maxLineLength = 256;
  char line[256];             /* Line from config file */
  char var[64];               /* (type=string) Parameter Name  in each line*/
  char value[256];            /* (type=string) Parameter Value in each line*/
  Param P;
  Matrix H, sqrtH, sqrtHi;
  Location *vent = NULL;
  int i;
  int spd;
  int num_vents;
  double detH, sqrt_detH, Const, grid2;
  double grid_total = 0.0, pdf = 0.0, X_easting, Y_northing, XX, YY;

  system ("date");
  if (argc < 1) {
    fprintf(stderr, "USAGE: %s <file.conf>\n\n", argv[0]);
    return 1;
  }

  fprintf(stderr, "Opening and appending run info to to: logfile\n");
  LOG = fopen("logfile", "w");
  if (LOG == NULL) {
    fprintf(stderr, "\nERROR : Cannot open logfile [%s]!\n", strerror(errno));
    return 1;
  }
  fprintf(LOG, "Parameters:\n");
  fflush(LOG); 

  CONF = fopen(argv[1], "r"); /*open configuration file*/
  if (CONF == NULL) {
    fprintf(stderr, "\nERROR : Cannot open %s [%s]!\n", argv[1], strerror(errno));
    fclose (LOG);
    return 1;
  }
  
  while (fgets(line, maxLineLength, CONF) != NULL) {
		
    /*if first character is comment, new line, space, return to next line*/
    if (line[0] == '#' || line[0] == '\n' || line[0] == ' ') continue;
    
    /*print incoming parameter*/
    var[0] = '\0';
    value[0] = '\0';
    sscanf (line,"%s =%s", var, value); /*split line into before ' = ' and after*/
    fprintf(stdout, "%s = %s\n",var, value); /*print incoming parameter value*/
    fflush(stdout); 
    
    if (!strncmp(var, "SPD", strlen("SPD"))) { 
      sscanf(value, "%d", &P.spd);
      if (P.spd != 1 && P.spd != 2) { 
        fprintf(stderr, "Parameter SPD[%d] must = one of these options: 1 (calculate spatial density) or 2 (calculate spatial intensity)\n", P.spd);
        fclose(CONF);
        fclose(LOG);
        return 1;
      }
      fprintf(LOG, "%s = %d\n", var, P.spd); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "WEST", strlen("WEST"))) {
      sscanf(value, "%lf", &P.west);
      P.west /= 1000.0;
      fprintf(LOG, "%s = %lf\n",var, P.west); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "EAST", strlen("EAST"))) {
      sscanf(value, "%lf", &P.east);
      P.east /= 1000.0;
      fprintf(LOG, "%s = %lf\n",var, P.east); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "SOUTH", strlen("SOUTH"))) {
      sscanf(value, "%lf", &P.south);
      P.south /= 1000.0;
      fprintf(LOG, "%s = %lf\n",var, P.south); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "NORTH", strlen("NORTH"))) {
      sscanf(value, "%lf", &P.north);
      P.north /= 1000.0;
      fprintf(LOG, "%s = %lf\n",var, P.north); /*print incoming parameter value*/
    }
    else if (!strncmp(var, "SAMSE", strlen("SAMSE"))) { 
      sscanf(value, "%d", &P.samse);
      if (P.samse != 1 && P.samse != 0) { 
        fprintf(stderr, "Parameter SAMSE[%d] must = one of these options: 1 (use SAMSE method) or 0 (input X- and Y- smoothing and rotation directly)\n", P.samse);
        fclose(CONF);
        fclose(LOG);
        return 1;
      }
      fprintf(LOG, "%s = %d\n", var, P.samse); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "SMOOTH_X", strlen("SMOOTH_X"))) {
      sscanf(value, "%lf", &P.smooth_x);
      fprintf(LOG, "%s = %lf\n",var, P.smooth_x); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "SMOOTH_Y", strlen("SMOOTH_Y"))) {
      sscanf(value, "%lf", &P.smooth_y);
      fprintf(LOG, "%s = %lf\n",var, P.smooth_y); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "ROTATION", strlen("ROTATION"))) {
      sscanf(value, "%lf", &P.rotation);
      fprintf(LOG, "%s = %lf\n",var, P.rotation); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "GRID_SPACING", strlen("GRID_SPACING"))) {
      sscanf(value, "%lf", &P.grid_spacing);
      P.grid_spacing /= 1000.0;
      fprintf(LOG, "%s = %lf\n",var, P.grid_spacing); /*print incoming parameter value*/
    }
    else if (!strncmp(var, "EVENT_FILE", strlen("EVENT_FILE"))) { 
      P.event_file = (char*) GC_MALLOC(sizeof(char) * (strlen(value)+1));
      if (P.event_file == NULL) {
        fprintf(stderr, "\n[INITIALIZE] Out of Memory assigning EVENT_FILE!\n");
        fclose(CONF);
        fclose(LOG);
        return 1;
      }
      sscanf(value, "%s", P.event_file);
      fprintf(LOG, "%s = %s\n", var, P.event_file); /*print incoming parameter value*/
    }
    else if (!strncmp(var, "BANDWIDTH_FILE", strlen("BANDWIDTH_FILE"))) { 
      P.bandwidth_file = (char*) GC_MALLOC(sizeof(char) * (strlen(value)+1));
      if (P.bandwidth_file == NULL) {
        fprintf(stderr, "\n[INITIALIZE] Out of Memory assigning BANDWIDTH_FILE!\n");
        fclose(CONF);
        fclose(LOG);
        return 1;
      }
      sscanf(value, "%s", P.bandwidth_file);
      fprintf(LOG, "%s = %s\n", var, P.bandwidth_file); /*print incoming parameter value*/
    }
    else if  (!strncmp(var, "PLOT_DIR", strlen("PLOT_DIR"))) {
      P.plotter = (char*) GC_MALLOC(sizeof(char) * (strlen(value)+1));
      if (P.plotter == NULL) {
        fprintf(stderr, "\n[INITIALIZE] Out of Memory assigning plotter file!\n");
        fclose(CONF);
        fclose(LOG);
        return 1;
      }
      sscanf(value, "%s/plot_spd.gmt.pl", P.plotter);
      fprintf(LOG, "%s = %s\n",var, P.plotter); /*print incoming parameter value*/
    }
    
  }
  fflush(LOG);
  fclose(CONF); 
  
  if (P.samse > 0) {
    /* FIND BANDWIDTH using SAMSE bandwilsdth from R */
    fprintf (stderr, "\nOptimizing Pilot Bandwidth (SAMSE)\n");
    system ("touch bandwidth.dat");
    KOP = fopen("R-samse", "w");
    if (KOP == NULL) {
      fprintf (stderr, "\nERROR : Cannot create R-script file [%s]!\n", strerror(errno));
      fclose (LOG);
      return 1;
    }
    fprintf (LOG, "Creating R script file: R-samse\n");

    fprintf (KOP, "library(ks)\n");
    fprintf (KOP, "vents<-read.table(\"%s\")\n", P.event_file);
    fprintf (KOP, "bd <- Hpi(x=vents,nstage=2,pilot=\"samse\",pre=\"sphere\", binned=FALSE, amise=FALSE, deriv.order=0, verbose=FALSE,optim.fun=\"nlm\")\n"); /* command to run samse */
    fprintf (KOP, "sink(\"%s\")\n", P.bandwidth_file); /* designates write-to file */
    fprintf (KOP, "show(bd)\n"); 	/* should be 2x2 matrix */
    fprintf (KOP, "sink()\n"); /* clears sink */
    fclose (KOP);

    system("R CMD BATCH R-samse");
  } 
  
  BW = fopen (P.bandwidth_file, "r");
  if (BW == NULL) {
    fprintf (stderr, "\nERROR : Cannot open %s file [%s]!\n", P.bandwidth_file, strerror(errno));
    fclose (LOG);
    return 1;
  }
  
   i = 0; 
   H.h1 = H.h2 = H.h3 = H.h4 = 0;
   
   while (fgets (line, maxLineLength, BW) != NULL) {
     if (i > 2) break;
     if (!i) fprintf(LOG, "%s", line); 
     if (i == 1) {
       fprintf (LOG, "%s", line);
       sscanf (line, "[1,] %lf %lf", &H.h1, &H.h2);
     }
     if (i == 2) {
       fprintf (LOG, "%s", line);
       sscanf (line, "[2,] %lf %lf", &H.h3, &H.h4);
     }
     i++;
   }
   fclose (BW);
   H.h1 /= 1e6;
   H.h2 /= 1e6;
   H.h3 /= 1e6;
   H.h4 /= 1e6;
   
   fprintf (stderr, "%lf %lf\n", H.h1, H.h2);
   fprintf (stderr, "%lf %lf\n", H.h3, H.h4);


/*
# The bandwidth matrix via SAMSE 2-stage 
# pre-transformation 'sphering' R output
# units = square meters
#> bw_samse_vents <- Hpi(x=vents, nstage=2, pilot="samse", pre="sphere", binned=FALSE, amise=FALSE, deriv.order=0, verbose=FALSE,optim.fun="nlm")

#> show(bw_samse_vents)
#         [,1]     [,2]
#[1,] 17702123 -8106069
#[2,] -8106069 19934123

#units = square kilometers
*/

  /* Create output file */
  P.output_file = (char*) GC_MALLOC(sizeof(char) * (strlen(P.event_file) + strlen(".samse.xyz") + 1));
  if (P.output_file == NULL) {
    fprintf(stderr, "\n[INITIALIZE] Out of Memory assigning output filename!\n");
    fclose(LOG);
    return 1;
  }
  sprintf (P.output_file, "%s.samse.xyz", P.event_file);
  OUT = fopen (P.output_file, "w");
  if (OUT == NULL) {
    fprintf (stderr, "\nERROR : Cannot open output file %s [%s]!\n", P.output_file, strerror(errno));
    fclose (LOG);
    return 1;
  }
  fprintf(LOG, "Opening %s for output\n", P.output_file);
  fprintf(stderr, "Opening %s for output\n", P.output_file);
  fflush(LOG);
  
  /* Load vent locations */
  vent = load_file(&P, &num_vents, LOG);
  if (vent == NULL) {
    fprintf (stderr, "[ERROR]No vents read! Exiting.");
    fclose(LOG);
    return 1;
  }
/*  for (i = 0; i < num_vents; i++) {
    fprintf(stderr, "%d %lf %lf\n", i, (vent+i)->east, (vent+i)->north);
  }*/


  /* Calculate spatial density or intensity */
  spd = num_vents;

  if (P.spd == 2) { /* Calculate spatial intensity */
    fprintf (LOG, "Calculating spatial intensity.\n");
    fprintf (stderr, "Calculating spatial intensity.\n");
    spd = 1; 
  } else {
    fprintf (LOG, "Calculating spatial density; grid should sum to 1.\n");
    fprintf (stderr, "Calculating spatial density; grid should sum to 1.\n");
    fprintf (LOG, "Number of vents = %d\n", spd);
    fprintf (stderr, "Number of vents = %d\n", spd);
  }
  
  /* Calculate necessary constants for 
     the Gaussian kernel fuctions:
     square root of the bandwidth matrix
   */

  /* determinant of the bandwidth matrix */
  detH = determinant(&H);
  fprintf (LOG, "Determinant: %lf\n", detH);
  fprintf (stderr, "Determinant: %lf\n", detH);
  
  /* square root of the bandwidth matrix */
  if (sqrtM(&H, &sqrtH, detH)) {
    fprintf(stderr, "ERROR calculating square root matrix\n");
    fclose(LOG);
    return 0;
  }
  fprintf (LOG, "Square Root Matrix:\n");
  fprintf (LOG, "%lf %lf\n", sqrtH.h1, sqrtH.h2);
  fprintf (LOG, "%lf %lf\n", sqrtH.h3, sqrtH.h4);
  fprintf (stderr, "Square Root Matrix:\n");
  fprintf (stderr, "%lf %lf\n", sqrtH.h1, sqrtH.h2);
  fprintf (stderr, "%lf %lf\n", sqrtH.h3, sqrtH.h4);
  
  /* square root of the determinant */
  sqrt_detH = sqrt(detH);
  fprintf (LOG, "sqrt(Determinant): %lf\n", sqrt_detH);
  fprintf (stderr, "sqrt(Determinant): %lf\n", sqrt_detH);
  
  /* determinant of sqrtH 
  det_sqrtH = determinant(&sqrtH);
  fprintf (LOG, "Determinant(sqrtH): %lf\n", det_sqrtH);
  fprintf (stderr, "Determinant(sqrtH): %lf\n", det_sqrtH);
  */
  system ("date");
  /* inverse of the square root matrix */

  
  if (inv_matrix(&sqrtH, &sqrtHi)) {
    fclose(LOG);
    fprintf(stderr, "ERROR calculating inverse of square root matrix\n");
    return 0;
  }
  fprintf (LOG, "Inverse Square Root Matrix:\n");
  fprintf (LOG, "%lf %lf\n", sqrtHi.h1, sqrtHi.h2);
  fprintf (LOG, "%lf %lf\n", sqrtHi.h3, sqrtHi.h4);
  fprintf (stderr, "Inverse Square Root Matrix:\n");
  fprintf (stderr, "%lf %lf\n", sqrtHi.h1, sqrtHi.h2);
  fprintf (stderr, "%lf %lf\n", sqrtHi.h3, sqrtHi.h4);
  

/* gaussian constant
 This is to calculate spatial density
 that is derived by the number of vents.
*/

  Const = 2.0 * PI * sqrt_detH * (double)spd;
  fprintf (stderr, "Const: %lf = 2* %lf * %lf * %lf\n", Const, PI, sqrt_detH, (double)spd);
  fprintf (LOG, "Const: %lf = 2* %lf * %lf *%lf\n", Const, PI, sqrt_detH, (double)spd);
  
  /* Create the spatial intensity grid */
  grid_total = 0.0;
  grid2 = P.grid_spacing * P.grid_spacing;
  X_easting = P.west - P.grid_spacing;
  
  do {
    X_easting += P.grid_spacing;
    Y_northing = P.south - P.grid_spacing;
    do {
      Y_northing += P.grid_spacing;
     // fprintf(stderr, "%lf %lf %lf %lf\n", X_easting, Y_northing, P.east, P.north); 
      pdf = gauss(X_easting, Y_northing, vent, num_vents, Const, &sqrtHi);
      XX = X_easting * 1000.0;
      YY = Y_northing * 1000.0;
      pdf *= grid2;
      grid_total += pdf;
      if (pdf > 1.0) fprintf (stderr, "%lf \t %lf \t %g\n", XX, YY, pdf);
      fprintf (OUT, "%lf %lf %g\n", XX, YY, pdf);
    }while (Y_northing < P.north);
   
  }while (X_easting < P.east);

  
  fclose(LOG);
  fclose(OUT);
  fprintf (stderr, "Grid totals %g Finished Calculations.\n", grid_total);
  
  fprintf (stderr, "Now plotting ....\n");
  (void) sprintf (line, "perl plot_spd.gmt.pl %s/%s %s&\n", P.plotter, argv[1], P.output_file);
  system (line);
  fprintf (stderr, "%s", line);
  fprintf (stderr, "Done!\n");
  system ("date");
  return 0;
}