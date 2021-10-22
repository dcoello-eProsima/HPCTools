#include "mkl_lapacke.h"
#include <math.h> // fabs in check_result function
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

double *generate_matrix(int size, double *matrix) {
  int i;
  srand(1);
  for (i = 0; i < size * size; i++) {
    matrix[i] = rand() % 100;
  }

  return matrix;
}

void print_matrix(const char *name, double *matrix, int size) {
  int i, j;
  printf("matrix: %s \n", name);

  for (i = 0; i < size; i++) {
    for (j = 0; j < size; j++) {
      printf("%f ", matrix[i * size + j]);
    }
    printf("\n");
  }
}

int check_result(double *bref, double *b, int size) {
  int i;
  for (i = 0; i < size * size; i++) {
    if (fabs(bref[i] - b[i]) > 0.000001) {
      printf("%f, %f %f\n", bref[i], b[i], fabs(bref[i] - b[i]));
      return 0;
    }
  }
  return 1;
}

/*
DGESV computes the solution to a real system of linear equations
    A * X = B,
 where A is an N-by-N matrix and X and B are N-by-NRHS matrices.

 The LU decomposition with partial pivoting and row interchanges is
 used to factor A as
    A = P * L * U,
 where P is a permutation matrix, L is unit lower triangular, and U is
 upper triangular.  The factored form of A is then used to solve the
 system of equations A * X = B.


[in]	N
          N is INTEGER
          The number of linear equations, i.e., the order of the
          matrix A.  N >= 0.
[in]	NRHS
          NRHS is INTEGER
          The number of right hand sides, i.e., the number of columns
          of the matrix B.  NRHS >= 0.
[in,out]	A
          A is DOUBLE PRECISION array, dimension (LDA,N)
          On entry, the N-by-N coefficient matrix A.
          On exit, the factors L and U from the factorization
          A = P*L*U; the unit diagonal elements of L are not stored.
[in]	LDA
          LDA is INTEGER
          The leading dimension of the array A.  LDA >= max(1,N).
[out]	IPIV
          IPIV is INTEGER array, dimension (N)
          The pivot indices that define the permutation matrix P;
          row i of the matrix was interchanged with row IPIV(i).
[in,out]	B
          B is DOUBLE PRECISION array, dimension (LDB,NRHS)
          On entry, the N-by-NRHS matrix of right hand side matrix B.
          On exit, if INFO = 0, the N-by-NRHS solution matrix X.
[in]	LDB
          LDB is INTEGER
          The leading dimension of the array B.  LDB >= max(1,N).
[out]	INFO
          INFO is INTEGER
          = 0:  successful exit
          < 0:  if INFO = -i, the i-th argument had an illegal value
          > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization
                has been completed, but the factor U is exactly
                singular, so the solution could not be computed.

*/
int my_dgesv(int n, int nrhs, double *a, int lda, int *ipiv, double *b,
             int ldb) {

  // Replace with your implementation
  LAPACKE_dgesv(LAPACK_ROW_MAJOR, n, nrhs, a, lda, ipiv, b, ldb);
  return 0;
}

void swap(double *a, double *b) {
  double aux = *b;
  *b = *a;
  *a = aux;
}

// get mutable element
double *gme(int r, int c, int n_c, double *m) { return &m[c + r * n_c]; }

void row_interchange(int n_r, int n_c, int row_1, int row_2, double *m) {
  if (row_1 > n_r || row_2 > n_r) {
    return;
  }
  for (int i = 0; i < n_c; i++) { // loop vectorized
    swap(gme(row_1, i, n_c, m), gme(row_2, i, n_c, m));
  }
}

void get_identity_matrix(int n, double *identity) {
  memset(identity, 0, sizeof(double) * n * n);
  for (int i = 0; i < n; i++) {
    *gme(i, i, n, identity) = 1;
  }
}

void pa_lu_colum(int n_r, int n_c, int c, double *m, double *l) {
  double *elem = &m[c + c * n_c];
  for (int i = 1; i < n_r - c; i++) {
    int c_index = ((c + i) * n_c);
    double *next = &m[c + c_index];
    double n_d_e = *next / *elem;
    for (int j = 0; j < n_r; j++) { // loop vectorized
      m[j + c_index] -= m[j + (c * n_c)] * n_d_e;
    }
    l[c + c_index] += n_d_e;
  }
}

void solve_l(int n_r_a, int n_c_a, double *m, int n_c_b, double *b) {
  for (int arow = 0; arow < n_r_a; arow++) {
    int arow_nca = arow * n_c_a;
    int arow_ncb = arow * n_c_b;
    int arow_p_arow_nca = m[arow_nca + arow];
    for (int bcol = 0; bcol < n_c_b; bcol++) { // loop vectorized
      double add = 0.0;
      for (int acol = 0; acol < arow; acol++) {
        add += -1 * m[arow_nca + acol] * b[bcol + acol * n_c_b];
      }
      b[arow_ncb + bcol] = ((b[arow_ncb + bcol] + add) / arow_p_arow_nca);
    }
  }
}

void solve_u(int n_r_a, int n_c_a, double *m, int n_c_b, double *b) {
  for (int arow = n_r_a - 1; arow >= 0; arow--) {
    int arow_nca = arow * n_c_a;
    int arow_ncb = arow * n_c_b;
    for (int bcol = 0; bcol < n_c_b; bcol++) { // loop vectorized
      double add = 0.0;
      for (int acol = n_c_a - 1; acol > arow; acol--) {
        add += -1 * m[acol + arow_nca] * b[bcol + acol * n_c_b];
      }
      b[arow_ncb + bcol] = ((b[arow_ncb + bcol] + add) / m[arow_nca + arow]);
    }
  }
}

void check_permutations(int n, double *m, int n_r_b, int n_c_b, double *b) {
  for (int r = 0; r < n; r++) {
    if (!*gme(r, r, n, m)) {
      for (int r2 = 0; r2 < n; r2++) {
        if (*gme(r2, r, n, m) && *gme(r, r2, n, m)) {
          row_interchange(n, n, r, r2, m);
          row_interchange(n_r_b, n_c_b, r, r2, b);
          break;
        }
      }
    }
  }
}

void pa_lu(int n_r, int n_c, double *m, int n_r_b, int n_c_b, double *b,
           double *l) {
  get_identity_matrix(n_r, l);
  check_permutations(n_r, m, n_r_b, n_c_b, b);
  for (int colum = 0; colum < n_c - 1; colum++) {
    pa_lu_colum(n_r, n_c, colum, m, l);
  }

  solve_l(n_r, n_c, l, n_c_b, b);
  solve_u(n_r, n_c, m, n_c_b, b);
}

int main(int argc, char *argv[]) {

  int size = atoi(argv[1]);

  double *a = (double *)malloc(sizeof(double) * size * size);
  double *aref = (double *)malloc(sizeof(double) * size * size);
  double *b = (double *)malloc(sizeof(double) * size * size);
  double *bref = (double *)malloc(sizeof(double) * size * size);

  generate_matrix(size, a);
  generate_matrix(size, aref);
  generate_matrix(size, b);
  generate_matrix(size, bref);

  // Using MKL to solve the system
  MKL_INT n = size, nrhs = size, lda = size, ldb = size, info;
  MKL_INT *ipiv = (MKL_INT *)malloc(sizeof(MKL_INT) * size);

  clock_t tStart = clock();

  info = LAPACKE_dgesv(LAPACK_ROW_MAJOR, n, nrhs, aref, lda, ipiv, bref, ldb);
  printf("Time taken by MKL: %.2fs\n",
         (double)(clock() - tStart) / CLOCKS_PER_SEC);

  tStart = clock();
  MKL_INT *ipiv2 = (MKL_INT *)malloc(sizeof(MKL_INT) * size);
  double *l = (double *)malloc(sizeof(double) * n * n);
  pa_lu(size, size, a, size, size, b, l);
  free(l);
  // my_dgesv(n, nrhs, a, lda, ipiv2, b, ldb);
  printf("Time taken by my implementation: %.2fs\n",
         (double)(clock() - tStart) / CLOCKS_PER_SEC);

  if (check_result(bref, b, size) == 1)
    printf("Result is ok!\n");
  else
    printf("Result is wrong!\n");

  free(a);
  free(aref);
  free(b);
  free(bref);
  free(ipiv);
  free(ipiv2);

  // print_matrix("X", b, size);
  // print_matrix("Xref", bref, size);
  return 0;
}
